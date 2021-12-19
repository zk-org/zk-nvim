local lsp = require("zk.lsp")

local M = {}

local function execute_command(path, cmd, args, cb)
  lsp.start()
  lsp.client().request("workspace/executeCommand", {
    command = "zk." .. cmd,
    arguments = {
      path or vim.api.nvim_buf_get_name(0),
      args,
    },
  }, function(err, res)
    assert(not err, tostring(err))
    if res and cb then
      cb(res)
    end
  end, 0)
end

--- https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zkindex
function M.index(path, args, cb)
  execute_command(path, "index", args, cb)
end

--- https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zknew
function M.new(path, args, cb)
  execute_command(path, "new", args, cb)
end

--- https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zklist
function M.list(path, args, cb)
  execute_command(path, "list", args, cb)
end

M.tag = {}

--- https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zktaglist
function M.tag.list(path, args, cb)
  execute_command(path, "tag.list", args, cb)
end

return M
