local config = require("zk.config")

local M = {}

function M.pick_notes(notes, options, action)
  options = vim.tbl_extend(
    "force",
    { title = "Zk Notes", picker = config.options.picker, multi_select = true },
    options or {}
  )
  require("zk.pickers." .. options.picker).show_note_picker(notes, options, action)
end

function M.pick_tags(tags, options, cb)
  options = vim.tbl_extend(
    "force",
    { title = "Zk Tags", picker = config.options.picker, multi_select = true },
    options or {}
  )
  require("zk.pickers." .. options.picker).show_tag_picker(tags, options, cb)
end

function M.get_pick_notes_list_api_selection(options)
  options = vim.tbl_extend("force", { picker = config.options.picker }, options or {})
  return require("zk.pickers." .. options.picker).note_picker_list_api_selection
end

return M
