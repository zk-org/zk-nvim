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

--- NOTE: No need to manually call this. Automatically called via an |autocmd| if lsp.auto_attach is enabled.
function M.lsp_buf_auto_add(bufnr)
  -- check that the buffer is a file
  if vim.api.nvim_buf_get_option(bufnr, "buftype") == "nofile" then
    return
  end

  -- check that we got a match on the root directory
  local get_root_dir = config.options.lsp.auto_attach.root_dir
  if get_root_dir then
    if not get_root_dir(vim.api.nvim_buf_get_name(bufnr), bufnr) then
      return
    end
  end

  lsp.buf_add(bufnr)
end

return M
