local lsp = require("zk.lsp")
local config = require("zk.config")

local M = {}

function M.setup_lsp_auto_attach()
  --- NOTE: modified version of code in nvim-lspconfig
  local trigger
  local filetypes = config.options.lsp.auto_attach.filetypes
  if filetypes then
    trigger = "FileType " .. table.concat(filetypes, ",")
  else
    trigger = "BufReadPost *"
  end
  vim.api.nvim_command(string.format("autocmd %s lua require'zk.util'.lsp_buf_auto_add(0)", trigger))
end

---Checks whether the given path belongs to a notebook
---@param path string
---@return string? root
function M.notebook_root(path)
  return require("lspconfig.util").root_pattern(".zk")(path)
end

---Automatically called via an |autocmd| if lsp.auto_attach is enabled.
---@param bufnr number
function M.lsp_buf_auto_add(bufnr)
  if vim.api.nvim_buf_get_option(bufnr, "buftype") == "nofile" then
    return
  end

  if not M.notebook_root(vim.api.nvim_buf_get_name(bufnr)) then
    return
  end

  lsp.buf_add(bufnr)
end

function M.make_lsp_location()
  local params = vim.lsp.util.make_given_range_params()
  params.uri = params.textDocument.uri
  params.textDocument = nil
  return params
end

--- needed until https://github.com/neovim/neovim/pull/13896 is merged
---@param range table LSP range object
function M.get_text_in_range(range)
  local A = range["start"]
  local B = range["end"]

  local lines = vim.api.nvim_buf_get_lines(0, A.line, B.line + 1, true)
  if vim.tbl_isempty(lines) then
    return nil
  end
  lines[#lines] = string.sub(lines[#lines], 1, B.character)
  lines[1] = string.sub(lines[1], A.character + 1)
  return table.concat(lines, "\n")
end

return M
