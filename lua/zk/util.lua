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
    range = M.get_selected_range() -- workaround for neovim 0.6.1 bug (https://github.com/mickael-menu/zk-nvim/issues/19)
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
  local pos = location['range']['start']

  pos['line'] = pos['line'] - 1
  pos['character'] = pos['character'] + 1

  location['range']['start'] = pos
  location['range']['end'] = pos

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
      ["end"] = position
    }
  })
end

---Gets the text in the given range of the current buffer.
---Needed until https://github.com/neovim/neovim/pull/13896 is merged.
--
---@param range table contains {start} and {end} tables with {line} (0-indexed, end inclusive) and {character} (0-indexed, end exclusive) values
---@return string? text in range
function M.get_text_in_range(range)
  local A = range["start"]
  local B = range["end"]

  local lines = vim.api.nvim_buf_get_lines(0, A.line, B.line + 1, true)
  if vim.tbl_isempty(lines) then
    return nil
  end
  local MAX_STRING_SUB_INDEX = 2^31 - 1 -- LuaJIT only supports 32bit integers for `string.sub` (in block selection B.character is 2^31)
  lines[#lines] = string.sub(lines[#lines], 1, math.min(B.character, MAX_STRING_SUB_INDEX))
  lines[1] = string.sub(lines[1], math.min(A.character + 1, MAX_STRING_SUB_INDEX))
  return table.concat(lines, "\n")
end

---Gets the most recently selected range of the current buffer.
---That is the text between the '<,'> marks.
---Note that these marks are only updated *after* leaving the visual mode.
--
---@return table selected range, contains {start} and {end} tables with {line} (0-indexed, end inclusive) and {character} (0-indexed, end exclusive) values
function M.get_selected_range()
  -- code adjusted from `vim.lsp.util.make_given_range_params`
  -- we don't want to use character encoding offsets here

  local A = vim.api.nvim_buf_get_mark(0, "<")
  local B = vim.api.nvim_buf_get_mark(0, ">")

  -- convert to 0-index
  A[1] = A[1] - 1
  B[1] = B[1] - 1
  if vim.o.selection ~= "exclusive" then
    B[2] = B[2] + 1
  end
  return {
    start = { line = A[1], character = A[2] },
    ["end"] = { line = B[1], character = B[2] },
  }
end

return M
