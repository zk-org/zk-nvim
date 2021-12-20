local util = require("zk.util")
local config = require("zk.config")

local M = {}

M.api = require("zk.api")

M.lsp = require("zk.lsp")

function M.setup(options)
  config.options = vim.tbl_deep_extend("force", config.defaults, options or {})

  if config.options.lsp.auto_attach.enabled then
    util.setup_lsp_auto_attach()
  end

  if config.options.create_user_commands then
    vim.cmd("command! ZkIndex lua require('zk').index()")
    vim.cmd("command! -nargs=? ZkNew lua require('zk').new(nil, { dir = [=[<args>]=]})")
  end
end

-- Commands

function M.index(path, args)
  M.api.index(path, args, function(stats)
    vim.notify(vim.inspect(stats))
  end)
end

function M.new(path, args)
  M.api.new(path, args, function(res)
    vim.cmd("edit " .. res.path)
  end)
end

return M
