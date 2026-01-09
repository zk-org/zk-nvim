local config = require("zk.config")

local M = {}

---Opens a notes picker
--
---@param options? table containing {picker}, {title}, {multi_select} keys
---@param cb function
function M.pick_notes(notes, options, cb)
  options = vim.tbl_extend(
    "force",
    { title = "Zk Notes", picker = config.options.picker, multi_select = true },
    config.options.picker_options or {},
    options or {}
  )
  require("zk.pickers." .. options.picker).show_note_picker(notes, options, cb)
end

---Opens a tags picker
--
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
  return require("zk.pickers." .. options.picker).note_picker_list_api_selection
end

return M
