local util = require("zk.util")
local config = require("zk.config")

local M = {}

M.api = require("zk.api")

M.lsp = require("zk.lsp")

---The entry point of the plugin
---@param options? table user configuration options
function M.setup(options)
  config.options = vim.tbl_deep_extend("force", config.defaults, options or {})

  if config.options.lsp.auto_attach.enabled then
    util.setup_lsp_auto_attach()
  end

  if config.options.create_user_commands then
    vim.cmd("command! ZkIndex lua require('zk').index()")
    vim.cmd("command! -nargs=? ZkNew lua require('zk').new(nil, { dir = <q-args> })") -- the command arg (directory) is interpreted relative to the notebook root
    -- vim.cmd("command! -nargs=? -complete=dir ZkNew lua require('zk').new(nil, { dir = vim.fn.fnamemodify(<q-args>, ':p') })") -- this would interpret the command arg (dir) relative to the cwd instead
    vim.cmd(
      "command! -nargs=? -complete=lua ZkList lua require('zk').list(nil, assert(loadstring('return ' .. <q-args>))())"
    )
    vim.cmd(
      "command! -nargs=? -complete=lua ZkTagList lua require('zk').tag.list(nil, assert(loadstring('return ' .. <q-args>))())"
    )
  end
end

-- Commands

---Indexes the notebook
--
---@param path? string path to explicitly specify the notebook
---@param options table additional options
---@see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zkindex
function M.index(path, options)
  M.api.index(path, options, function(stats)
    vim.notify(vim.inspect(stats))
  end)
end

---Creates and opens a new note
--
---@param path? string path to explicitly specify the notebook
---@param options table additional options
---@see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zknew
function M.new(path, options)
  M.api.new(path, options, function(res)
    vim.cmd("edit " .. res.path)
  end)
end

---Opens a Telescope picker
--
---@param path? string path to explicitly specify the notebook
---@param options table additional options
---@see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zklist
function M.list(path, options)
  -- NOTE: this does not have to be telescope specific.
  -- In the future consider exposing something like config.options.picker = 'telescope'|'fzf'|'builtin'.
  -- Obviously the same applies to the `M.tag.list` function.
  if path then
    options = options or {}
    options.path = path
  end
  -- `h: telescope.command`
  require("telescope._extensions.zk").exports.notes(options)
end

M.tag = {}

---Opens a Telescope picker
--
---@param path? string path to explicitly specify the notebook
---@param options table additional options
---@see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zktaglist
function M.tag.list(path, options)
  if path then
    options = options or {}
    options.path = path
  end
  require("telescope._extensions.zk").exports.tags(options)
end

return M
