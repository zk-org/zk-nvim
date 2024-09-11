local M = {}

---Finds the root directory of the notebook of the given path
--
---@param notebook_path string
---@return string? root
function M.notebook_root(notebook_path)
  return require("zk.root_pattern_util").root_pattern(".zk")(notebook_path)
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

---Makes an LSP location object from the last selection in the current buffer.
--
---@return table LSP location object
---@see https://microsoft.github.io/language-server-protocol/specifications/specification-current/#location
function M.get_lsp_location_from_selection()
  local params = vim.lsp.util.make_given_range_params()
  return {
    uri = params.textDocument.uri,
    range = params.range
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
  local params = vim.lsp.util.make_given_range_params()

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

---Gets the text in the last visual selection
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

return M
