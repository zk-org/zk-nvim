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

return M
