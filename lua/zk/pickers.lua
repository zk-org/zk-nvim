local config = require("zk.config")

local M = {}

local function invalid_picker(picker)
  vim.notify(string.format("Invalid picker '%s'", picker), vim.log.levels.ERROR)
end

function M.note_picker(notes, title, picker)
  picker = picker or config.options.picker
  title = title or "Zk Notes"
  if picker == "telescope" then
    require("telescope.zk.util").show_note_picker(notes, { prompt_title = title })
  else
    invalid_picker(picker)
  end
end

function M.make_note_picker_api_options(defaults, options, picker)
  picker = picker or config.options.picker -- yet unused in this context
  if picker == "telescope" then
    return vim.tbl_deep_extend(
      "force",
      require("telescope.zk.util").note_picker_api_options,
      defaults or {},
      options or {}
    )
  else
    invalid_picker(picker)
  end
end

function M.tag_picker(tags, title, cb, picker)
  picker = picker or config.options.picker
  title = title or "Zk Tags"
  if picker == "telescope" then
    require("telescope.zk.util").show_tag_picker(tags, { prompt_title = title }, cb)
  else
    invalid_picker(picker)
  end
end

function M.make_tag_picker_api_options(defaults, options, picker) -- 3rd argument
  picker = picker or config.options.picker -- yet unused in this context
  if picker == "telescope" then
    return vim.tbl_deep_extend(
      "force",
      require("telescope.zk.util").tag_picker_api_options,
      defaults or {},
      options or {}
    )
  else
    invalid_picker(picker)
  end
end

return M
