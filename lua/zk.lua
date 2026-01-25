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

---Prompt for a new note with groups, paths, templates, and directories selections.
--
---@param options? table
---@param cb fun(options: table?, toml: table?)
function M.new_prompt(options, cb)
  cwd = options and options.notebook_path or util.notebook_root(vim.fn.getcwd())
  if not cwd then
    return
  end
  local toml = util.get_config_toml(cwd) or {}
  local groups = toml.group -- Note that it is named `group` instead of `groups` in config.toml

  ---@param a string
  ---@param b string
  ---@return boolean
  local function sorter(a, b)
    return a < b
  end

  ---@param group_names string[]
  ---@param on_select function
  function select_group(group_names, on_select)
    table.sort(group_names, sorter)
    vim.ui.select(group_names, { prompt = "Select a group" }, function(group_name)
      if not group_name then
        return
      end
      options.group = group_name
      on_select()
    end)
  end

  ---@param on_select function
  function select_directory_fs(on_select)
    local dirs = util.get_dirs(cwd) or {}
    table.insert(dirs, "")
    table.sort(dirs, sorter)
    vim.ui.select(dirs, { prompt = "Select a directory" }, function(dir)
      if not dir then
        return
      end
      options.dir = dir
      on_select()
    end)
  end

  ---@param paths string[]
  ---@param on_select function
  function select_paths(paths, on_select)
    table.sort(paths, sorter)
    if #paths > 1 then
      vim.ui.select(paths, { prompt = "Select a path" }, function(path)
        if not path then
          return
        end
        options.dir = path
        options.template = groups[options.group].note and groups[options.group].note.template
        on_select()
      end)
    elseif #paths == 1 then -- Apply automatically if only one path
      options.dir = paths[1]
      options.template = groups[options.group].note and groups[options.group].note.template
      on_select()
    end
  end

  ---@param on_select function
  function select_template_fs(on_select)
    local templates = util.get_templates(cwd)
    if not templates or vim.tbl_count(templates) == 0 then
      local msg = "Cannot find any templates in `.zk/templates`"
      vim.notify(msg, vim.log.levels.ERROR, { title = "zk-nvim" })
      return
    end

    local template_names = {}
    for _, template in pairs(templates) do
      table.insert(template_names, template.name)
    end
    table.sort(template_names, sorter)
    vim.ui.select(template_names, { prompt = "Select a template" }, function(template_name)
      if not template_name then
        return
      end
      options.template = template_name
      on_select()
    end)
  end

  if groups then -- groups exists
    local group_names = vim.tbl_keys(groups)
    select_group(group_names, function()
      local paths = groups[options.group] and groups[options.group].paths
      if paths then -- paths exists
        select_paths(paths, function()
          local template_name = groups[options.group].note and groups[options.group].note.template
          if template_name then
            options.template = template_name
            cb(options, toml)
          else
            select_template_fs(function()
              cb(options, toml)
            end)
          end
        end)
      else -- paths does not exist
        select_directory_fs(function()
          local template_name = groups[options.group].note and groups[options.group].note.template
          if template_name then
            options.template = template_name
            cb(options, toml)
          else
            select_template_fs(function()
              cb(options, toml)
            end)
          end
        end)
      end
    end)
  else -- groups does not exist
    select_directory_fs(function()
      select_template_fs(function()
        cb(options, toml)
      end)
    end)
  end
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
