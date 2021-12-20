local lsp = require("zk.lsp")
local util = require("zk.util")

local M = {}

local function resolve_notebook_dir(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  -- if the buffer has no name, use the current working directory
  if path == "" then
    path = vim.fn.getcwd(0)
  end
  -- if the buffer doesn't belong to a notebook, use $ZK_NOTEBOOK_DIR as fallback if available
  if not util.is_notebook_path(path) and vim.env.ZK_NOTEBOOK_DIR then
    path = vim.env.ZK_NOTEBOOK_DIR
  end
  return path
end

local function execute_command(path, cmd, args, cb)
  local bufnr = 0
  lsp.start()
  lsp.client().request("workspace/executeCommand", {
    command = "zk." .. cmd,
    arguments = {
      path or resolve_notebook_dir(bufnr),
      args,
    },
  }, function(err, res)
    assert(not err, tostring(err))
    if res and cb then
      cb(res)
    end
  end, bufnr)
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
