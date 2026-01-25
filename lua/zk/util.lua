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
  local region = vim.fn.getregionpos(vim.fn.getpos("'<"), vim.fn.getpos("'>"), { exclusive = false })

  local chunks = {}
  local maxcol = vim.v.maxcol
  for _, segment in ipairs(region) do
    -- each segment is two positions: start and end
    local start_pos, end_pos = segment[1], segment[2]
    -- buffer and line don't change between start and end -> use start only
    -- Note getregionpos returns 1-based indexing, but get_text expects 0-based
    local bufnr, line = start_pos[1], start_pos[2] - 1
    local startcol = start_pos[3] - 1
    local endcol = end_pos[3] -- 0-indexing, but we want to include the last col so
    endcol = endcol == maxcol and -1 or endcol
    local chunk = vim.api.nvim_buf_get_text(bufnr, line, startcol, line, endcol, {})[1]
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

    if vim.api.nvim_buf_is_loaded(buf) and path ~= "" then
      table.insert(paths, path)
    end
  end

  return paths
end

---Load and decode 'config.toml'
---@param cwd? string Notebook root directory (optional)
---@return table? config Decoded TOML config if successful
function M.get_config_toml(cwd)
  local ltoml = require("toml")
  cwd = cwd or require("zk.util").notebook_root(vim.fn.getcwd())
  if not cwd then
    return
  end
  toml_path = vim.fs.joinpath(cwd, ".zk/config.toml")
  local result, config = pcall(ltoml.decodeFromFile, toml_path)
  if not result then
    vim.notify("Error: Cannot get 'config.toml'.", vim.log.levels.ERROR, { title = "zk-nvim" })
    return
  end
  return config
end

---Get templates list
---@param cwd string?
---@return table<string, {name:string, path:string, content:string}>? temlates
function M.get_templates(cwd)
  cwd = cwd or require("zk.util").notebook_root(vim.fn.getcwd())
  if not cwd then
    return
  end
  local template_dir = vim.fs.joinpath(cwd, ".zk/templates")
  local paths = vim.fn.globpath(template_dir, "*.md", false, true)
  local templates = {}
  for _, path in ipairs(paths) do
    local template = {
      path = path,
      name = vim.fn.fnamemodify(path, ":t"),
      stem = vim.fn.fnamemodify(path, ":t:r"),
      content = table.concat(vim.fn.readfile(path), "\n"),
    }
    templates[path] = template
  end
  return templates
end

---Get directories list
---@param cwd string?
---@param depth number?
---@param ignores table?
---@return table? directories
function M.get_dirs(cwd, depth, ignores)
  cwd = cwd or require("zk.util").notebook_root(vim.fn.getcwd())
  if not cwd then
    return
  end
  depth = depth or 10
  ignores = ignores or {}
  local dirs = {}
  for name, type in vim.fs.dir(cwd, { depth = depth }) do
    if type == "directory" then
      local segments = vim.split(name, "[/\\]")
      local hidden = false
      local ignored = false
      for _, segment in ipairs(segments) do
        if segment:sub(1, 1) == "." then
          hidden = true
          break
        end
        for _, part in ipairs(ignores) do
          if segment == part then
            ignored = true
            break
          end
        end
      end
      if not hidden and not ignored then
        table.insert(dirs, name)
      end
    end
  end
  return dirs
end

return M
