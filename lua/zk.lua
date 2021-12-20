local util = require("zk.util")
local config = require("zk.config")

local M = {}

M.api = require("zk.api")

M.lsp = require("zk.lsp")

M.cmd = require("zk.cmd")

function M.setup(options)
  config.options = vim.tbl_deep_extend("force", config.defaults, options or {})
  if config.options.lsp.auto_attach.enabled then
    util.setup_lsp_auto_attach()
  end
end

vim.cmd("command! ZkIndex lua require('zk').cmd.index()")
vim.cmd("command! -nargs=? ZkNew lua require('zk').cmd.new(nil, { dir = [=[<args>]=]})")

return M
