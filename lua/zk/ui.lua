local config = require("zk.config")

local M = {}

---Opens a notes picker
--
---@param notes list
---@param options? table containing {picker}, {title}, {multi_select} keys
---@param cb function
function M.pick_notes(notes, options, cb)
  options = vim.tbl_extend(
    "force",
    { title = "Zk Notes", picker = config.options.picker, multi_select = true },
    config.options.picker_options or {},
    options or {},
    options.notebook_path and { notebook_path = options.notebook_path } or {}
  )
  require("zk.pickers." .. options.picker).show_note_picker(notes, options, cb)
end

---Opens a notes grep picker
--
---@param options? table containing {notebook_path}, {picker}, {multi_select} keys
---@param picker_options? table
---@param cb function
function M.grep_notes(options, picker_options, cb)
  options = vim.tbl_extend(
    "force",
    { title = "Zk Grep", picker = config.options.picker, multi_select = true },
    config.options.picker_options or {},
    options or {},
    picker_options or {},
    options.notebook_path and { notebook_path = options.notebook_path } or {}
  )
  if options.picker ~= "telescope" and options.picker ~= "snacks_picker" then
    print(":ZkGrep is only usable with telescope and snacks_picker.")
    return
  end
  require("zk.pickers." .. options.picker).show_grep_picker(options, cb)
end

---Opens a tags picker
--
---@param tags list
---@param options? table containing {picker}, {title}, {multi_select} keys
---@param cb function
function M.pick_tags(tags, options, cb)
  options = vim.tbl_extend(
    "force",
    { title = "Zk Tags", picker = config.options.picker, multi_select = true },
    config.options.picker_options or {},
    options or {}
  )
  require("zk.pickers." .. options.picker).show_tag_picker(tags, options, cb)
end

---To be used in zk.api.list as the `selection` in the additional options table
--
---@param options table the same options that are use for pick_notes
---@return table api selection
function M.get_pick_notes_list_api_selection(options)
  options = vim.tbl_extend(
    "force",
    { picker = config.options.picker },
    config.options.picker_options or {},
    options or {}
  )
  return require("zk.pickers." .. options.picker).zk_api_select
end

return M
