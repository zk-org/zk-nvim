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
    vim.cmd([[
      " Core Commands
      command! -nargs=? -complete=lua ZkIndex   lua require('zk').index(nil, assert(loadstring('return ' .. <q-args>))())
      command! -nargs=? -complete=lua ZkNew     lua require('zk').new(nil, assert(loadstring('return ' .. <q-args>))())
      command! -nargs=? -complete=lua ZkList    lua require('zk').list(nil, assert(loadstring('return ' .. <q-args>))())
      command! -nargs=? -complete=lua ZkTagList lua require('zk').tag.list(nil, assert(loadstring('return ' .. <q-args>))())

      " Convenience Commands
      command! -range -nargs=? -complete=lua ZkNewLink lua assert(<range> == 2, "ZkNewLink must be called with '<,'> range. Try :'<'>ZkNewLink"); require('zk').new_link(nil, assert(loadstring('return ' .. <q-args>))())
    ]])
    -- The definition of :ZkNewLink is kind of a hack.
    -- The lua function that is called by ZkNewLink will always use the '<,'> marks to get the selection.
    -- The only way that this command can be called that makes semantical sense is :'<,'>ZkNewLink.
  end
end

-- Core Commands

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

---Creates a new note
--
---@param path? string path to explicitly specify the notebook
---@param options table additional options
---@see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zknew
function M.new(path, options)
  -- neovim does not yet support window/showDocument, therefore we handle options.edit locally
  if options and options.edit then
    options.edit = nil -- nil means true in this context
  end
  M.api.new(path, options, function(res)
    if options and options.edit == false then
      return
    end
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

-- Convenience Commands

---Creates a new note and uses the last visual selection as the title while replacing the selection with a link to the new note
--
---@param path? string path to explicitly specify the notebook
---@param options table additional options
function M.new_link(path, options)
  local location = util.make_lsp_location()
  local selected_text = util.get_text_in_range(location.range)
  if not selected_text then
    vim.notify("Selection not set", vim.log.levels.ERROR)
    return
  end
  M.new(path, vim.tbl_extend("keep", options or {}, { insertLinkAtLocation = location, title = selected_text }))
end

return M
