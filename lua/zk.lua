local lsp = require("zk.lsp")
local config = require("zk.config")
local ui = require("zk.ui")
local api = require("zk.api")
local util = require("zk.util")

local M = {}

local function setup_lsp_auto_attach()
  --- NOTE: modified version of code in nvim-lspconfig
  local trigger
  local filetypes = config.options.lsp.config.filetypes
  if filetypes then
    trigger = "FileType " .. table.concat(filetypes, ",")
  else
    trigger = "BufReadPost *"
  end
  M._lsp_buf_auto_add(0)
  vim.api.nvim_command(string.format("autocmd %s lua require'zk'._lsp_buf_auto_add(0)", trigger))
end

---Automatically called via an |autocmd| if lsp.auto_attach is enabled.
--
---@param bufnr number
function M._lsp_buf_auto_add(bufnr)
  if vim.api.nvim_buf_get_option(bufnr, "buftype") == "nofile" then
    return
  end

  if not util.notebook_root(vim.api.nvim_buf_get_name(bufnr)) then
    return
  end

  lsp.buf_add(bufnr)
end

---The entry point of the plugin
--
---@param options? table user configuration options
function M.setup(options)
  config.options = vim.tbl_deep_extend("force", config.defaults, options or {})

  if config.options.lsp.auto_attach.enabled then
    setup_lsp_auto_attach()
  end

  require("zk.commands.builtin")
  util.set_autocmd_for_update()
end

---Cd into the notebook root
--
---@param options? table
function M.cd(options)
  options = options or {}
  local notebook_path = options.notebook_path or util.resolve_notebook_path(0)
  local root = util.notebook_root(notebook_path)
  if root then
    vim.cmd("cd " .. root)
  end
end

---Creates and edits a new note
--
---@param options? table additional options
---@see https://github.com/zk-org/zk/blob/main/docs/tips/editors-integration.md#zknew
function M.new(options)
  options = options or {}
  api.new(options.notebook_path, options, function(err, res)
    assert(not err, tostring(err))
    if options and options.dryRun ~= true and options.edit ~= false then
      -- neovim does not yet support window/showDocument, therefore we handle options.edit locally
      vim.cmd("edit " .. res.path)
    end
  end)
end

---Indexes the notebook
--
---@param options? table additional options
---@param cb? function for processing stats
---@see https://github.com/zk-org/zk/blob/main/docs/tips/editors-integration.md#zkindex
function M.index(options, cb)
  options = options or {}
  cb = cb or function(stats)
    vim.notify(vim.inspect(stats))
  end
  api.index(options.notebook_path, options, function(err, stats)
    assert(not err, tostring(err))
    cb(stats)
  end)
end

---Opens a notes picker, and calls the callback with the selection
--
---@param options? table additional options
---@param picker_options? table options for the picker
---@param cb function
---@see https://github.com/zk-org/zk/blob/main/docs/tips/editors-integration.md#zklist
---@see zk.ui.pick_notes
function M.pick_notes(options, picker_options, cb)
  options =
    vim.tbl_extend("force", { select = ui.get_pick_notes_list_api_selection(picker_options) }, options or {})
  if options["notebook_path"] then
    picker_options["notebook_path"] = options["notebook_path"]
  end
  api.list(options.notebook_path, options, function(err, notes)
    assert(not err, tostring(err))
    ui.pick_notes(notes, picker_options, cb)
  end)
end

---Opens a tags picker, and calls the callback with the selection
--
---@param options? table additional options
---@param picker_options? table options for the picker
---@param cb function
---@see https://github.com/zk-org/zk/blob/main/docs/tips/editors-integration.md#zktaglist
---@see zk.ui.pick_tags
function M.pick_tags(options, picker_options, cb)
  options = options or {}
  api.tag.list(options.notebook_path, options, function(err, tags)
    assert(not err, tostring(err))
    ui.pick_tags(tags, picker_options, cb)
  end)
end

---Opens a notes picker, and edits the selected notes
--
---@param options? table additional options
---@param picker_options? table options for the picker
---@see https://github.com/zk-org/zk/blob/main/docs/tips/editors-integration.md#zklist
---@see zk.ui.pick_notes
function M.edit(options, picker_options)
  M.pick_notes(options, picker_options, function(notes)
    if picker_options and picker_options.multi_select == false then
      notes = { notes }
    end
    for _, note in ipairs(notes) do
      vim.cmd("e " .. note.absPath)
    end
  end)
end

return M
