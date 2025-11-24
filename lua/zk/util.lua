local M = {}

---Finds the root directory of the notebook of the given path
--
---@param notebook_path string
---@return string? root
function M.notebook_root(notebook_path)
  local root_pattern = require("zk.root_pattern_util").root_pattern(".zk")
  local rp = root_pattern(notebook_path)
  return rp
  -- return require("zk.root_pattern_util").root_pattern(".zk")(notebook_path)
end

---Try to resolve a notebook path by checking the following locations in that order
---1. current buffer path
---2. current working directory
---3. `$ZK_NOTEBOOK_DIR` environment variable
---
---Note that the path will not necessarily be the notebook root.
--
---@param bufnr number?
---@return string? path inside a notebook
function M.resolve_notebook_path(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  local cwd = vim.fn.getcwd(0)
  -- if the buffer has no name (i.e. it is empty), set the current working directory as it's path
  if path == "" then
    path = cwd
  end
  if not M.notebook_root(path) then
    if not M.notebook_root(cwd) then
      -- if neither the buffer nor the cwd belong to a notebook, use $ZK_NOTEBOOK_DIR as fallback if available
      if vim.env.ZK_NOTEBOOK_DIR then
        path = vim.env.ZK_NOTEBOOK_DIR
      end
    else
      -- the buffer doesn't belong to a notebook, but the cwd does!
      path = cwd
    end
  end
  -- at this point, the buffer either belongs to a notebook, or everything else failed
  return path
end

local function get_offset_encoding(bufnr)
  -- Modified from nvim's vim.lsp.util._get_offset_encoding()
  vim.validate("bufnr", bufnr, "number", true)
  local zk_client = vim.lsp.get_clients({ bufnr = bufnr, name = "zk" })[1]
  local error_level = vim.log.levels.ERROR
  local offset_encoding --- @type 'utf-8'|'utf-16'|'utf-32'
  if zk_client == nil then
    vim.notify_once("No zk client found for this buffer. Using default encoding of utf-16", error_level)
    offset_encoding = "utf-16"
  elseif zk_client.offset_encoding == nil then
    vim.notify_once(
      string.format("ZK Client (id: %s) offset_encoding is nil. Do not unset offset_encoding.", zk_client.id),
      error_level
    )
  else
    offset_encoding = zk_client.offset_encoding
  end
  return offset_encoding
end

local function make_range_zk()
  local bufnr = vim.api.nvim_get_current_buf()
  local offset_encoding = get_offset_encoding(bufnr)
  -- This function has a warning if encoding is not passed
  return vim.lsp.util.make_given_range_params(nil, nil, bufnr, offset_encoding)
end

---Makes an LSP location object from the last selection in the current buffer.
--
---@return table LSP location object
---@see https://microsoft.github.io/language-server-protocol/specifications/specification-current/#location
function M.get_lsp_location_from_selection()
  local params = make_range_zk()
  return {
    uri = params.textDocument.uri,
    range = params.range,
  }
end

---Fix to correct cursor location
--
---When working on link insertion, it was discovered that there may be
---an off-by-one error for single point locations in glsp. This function
---corrects that error.
---@param location table An LSP location object representing a single cell
---@return table The LSP location corrected one row up and one column right
---@internal
local function fix_cursor_location(location)
  -- Cursor LSP position is a little weird.
  -- It inserts one line down. Seems like an off by one error somewhere
  local pos = location["range"]["start"]

  pos["line"] = pos["line"] - 1
  pos["character"] = pos["character"] + 1

  location["range"]["start"] = pos
  location["range"]["end"] = pos

  return location
end

---Makes an LSP location object from the caret position in the current buffer.
--
---@return table LSP location object
---@see https://microsoft.github.io/language-server-protocol/specifications/specification-current/#location
function M.get_lsp_location_from_caret()
  local params = make_range_zk()

  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local position = { line = row, character = col }
  return fix_cursor_location({
    uri = params.textDocument.uri,
    range = {
      start = position,
      ["end"] = position,
    },
  })
end

---Gets the text in the last visual selection.
--
---@return string text in range
function M.get_selected_text()
  local region = vim.region(0, "'<", "'>", vim.fn.visualmode(), true)

  local chunks = {}
  local maxcol = vim.v.maxcol
  for line, cols in vim.spairs(region) do
    local endcol = cols[2] == maxcol and -1 or cols[2]
    local chunk = vim.api.nvim_buf_get_text(0, line, cols[1], line, endcol, {})[1]
    table.insert(chunks, chunk)
  end
  return table.concat(chunks, "\n")
end

---Gets the file paths of active buffers.
--
---@return table Paths of currently active buffers.
function M.get_buffer_paths()
  local buffers = vim.api.nvim_list_bufs()
  local paths = {}

  for _, buf in ipairs(buffers) do
    local path = vim.api.nvim_buf_get_name(buf)

    if path ~= "" then
      table.insert(paths, path)
    end
  end

  return paths
end

---Auto update lines
---@param trigger_name string
function M.update(trigger_name)
  local opts = require("zk.config").options
  local trigger = opts.update.triggers[trigger_name]
  if not opts.update.enabled or not trigger.enabled then
    return
  end

  local YAML_DELIMITER = "^%-%-%-"
  local path = vim.api.nvim_buf_get_name(0)
  local root = M.notebook_root(vim.api.nvim_buf_get_name(0))
  local all_rules = trigger.rules

  ---@param notebook_paths string[]
  ---@return boolean is_allowed_notebook_path
  local function is_notebook_allowed(notebook_paths)
    if not notebook_paths or #notebook_paths == 0 then
      return true
    end
    for _, notebook_path in ipairs(notebook_paths) do
      if notebook_path == root then
        return true
      end
    end
    return false
  end

  ---@param dirs string[]
  ---@return boolean is_allowed_directory
  local function is_dir_allowed(dirs)
    if not dirs or #dirs == 0 then
      return true
    end
    for _, dir in ipairs(dirs) do
      if path:find(vim.fs.joinpath(root, dir), 1, true) then
        return true
      end
    end
    return false
  end

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local rules = {}

  -- Keep only the valid rules for the notebook_paths and dirs
  for _, rule in pairs(all_rules) do
    if is_notebook_allowed(rule.notebook_paths) then
      if is_dir_allowed(rule.dirs) then
        table.insert(rules, rule)
      end
    end
  end

  local in_yaml = false
  for i, line in ipairs(lines) do
    if line:match(YAML_DELIMITER) then
      in_yaml = not in_yaml
    end
    for _, rule in ipairs(rules) do
      if rule.in_yaml == in_yaml then
        captures = { line:match(rule.pattern) }
        if #captures > 0 then
          lines[i] = rule.format(captures, line)
        end
      end
    end
  end

  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

function M.set_autocmd_for_update()
  local opts = require("zk.config").options
  for trigger_name, triger in pairs(opts.update.triggers) do
    local event = triger.event
    local msg = string.format("'event' field is not set in %s", trigger_name)
    if not event then
      vim.notify(msg, vim.log.levels.INFO, { title = "zk-nvim" })
    end
    vim.api.nvim_create_autocmd(triger.event, {
      pattern = "*.md",
      callback = function()
        M.update(trigger_name)
      end,
    })
  end
end

return M
