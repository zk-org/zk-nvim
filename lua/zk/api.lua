local lsp = require("zk.lsp")
local util = require("zk.util")

local M = {}

---Executes the given command via LSP
--
---@param cmd string
---@param path string?
---@param options table?
---@param cb function?
local function execute_command(cmd, path, options, cb)
  if options and vim.tbl_isempty(options) then
    -- an empty table would be send as an empty list, which causes an error on the server
    options = nil
  end
  local bufnr = 0
  lsp.client().request("workspace/executeCommand", {
    command = "zk." .. cmd,
    arguments = {
      path or util.resolve_notebook_path(bufnr),
      options,
    },
  }, cb, bufnr)
end

---@param path? string path to explicitly specify the notebook
---@param options? table additional options
---@param cb function callback function
---@see https://github.com/zk-org/zk/blob/main/docs/editors-integration.md#zkindex
function M.index(path, options, cb)
  execute_command("index", path, options, cb)
end

---@param path? string path to explicitly specify the notebook
---@param options? table additional options
---@param cb function callback function
---@see https://github.com/zk-org/zk/blob/main/docs/editors-integration.md#zknew
function M.new(path, options, cb)
  execute_command("new", path, options, cb)
end

---@param target string path to note you want to link to
---@param location table LSP location at current caret
---@param path? string path to explicitly specify the notebook
---@param options? table Extra options; table in form {title: string}
---@param cb? function callback function
---@see https://github.com/zk-org/zk/blob/main/docs/editors-integration.md#zklink
function M.link(target, location, path, options, cb)
  options = vim.tbl_extend("force", { path = target, location = location }, options or {})

  execute_command("link", path, options, cb)
end

---@param path? string path to explicitly specify the notebook
---@param options table additional options
---@param cb function callback function
---@see https://github.com/zk-org/zk/blob/main/docs/editors-integration.md#zklist
function M.list(path, options, cb)
  execute_command("list", path, options, cb)
end

M.tag = {}

---@param path? string path to explicitly specify the notebook
---@param options? table additional options
---@param cb function callback function
---@see https://github.com/zk-org/zk/blob/main/docs/editors-integration.md#zktaglist
function M.tag.list(path, options, cb)
  execute_command("tag.list", path, options, cb)
end

return M
