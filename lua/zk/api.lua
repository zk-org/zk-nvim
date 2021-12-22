local lsp = require("zk.lsp")
local util = require("zk.util")

local M = {}

---Try to resolve the notebook directory by checking the following locations in that order
---1. current buffer path
---2. current working directory
---3. `$ZK_NOTEBOOK_DIR` environment variable
--
---@param bufnr number?
local function resolve_notebook_dir(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  local cwd = vim.fn.getcwd(0)
  -- if the buffer has no name (i.e. it is empty), set the current working directory as it's path
  if path == "" then
    path = cwd
  end
  if not util.notebook_root(path) then
    if not util.notebook_root(cwd) then
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

---Executes the given command via LSP
--
---@param cmd string
---@param path string?
---@param options table?
---@param cb function?
local function execute_command(cmd, path, options, cb)
  local bufnr = 0
  lsp.start()
  lsp.client().request("workspace/executeCommand", {
    command = "zk." .. cmd,
    arguments = {
      path or resolve_notebook_dir(bufnr),
      options,
    },
  }, function(err, res)
    assert(not err, tostring(err))
    if res and cb then
      cb(res)
    end
  end, bufnr)
end

---@param path? string path to explicitly specify the notebook
---@param options table additional options
---@param cb function callback function
---@see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zkindex
function M.index(path, options, cb)
  execute_command("index", path, options, cb)
end

---@param path? string path to explicitly specify the notebook
---@param options table additional options
---@param cb function callback function
---@see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zknew
function M.new(path, options, cb)
  execute_command("new", path, options, cb)
end

---@param path? string path to explicitly specify the notebook
---@param options table additional options
---@param cb function callback function
---@see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zklist
function M.list(path, options, cb)
  execute_command("list", path, options, cb)
end

M.tag = {}

---@param path? string path to explicitly specify the notebook
---@param options table additional options
---@param cb function callback function
---@see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zktaglist
function M.tag.list(path, options, cb)
  execute_command("tag.list", path, options, cb)
end

return M
