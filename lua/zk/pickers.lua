local config = require("zk.config")

local M = {}

local function invalid_picker(picker)
  return string.format("Invalid picker '%s'", picker)
end

function M.note_picker(notes, title, picker)
  picker = picker or config.options.picker
  title = title or "Zk Notes"
  if picker == "telescope" then
    require("telescope.zk.util").show_note_picker(notes, { prompt_title = title })
  elseif picker == "fzf" then
    require("zk.fzf").show_note_picker(notes, { "--header=" .. title })
  else
    error(invalid_picker(picker))
  end
end

function M.make_note_picker_api_options(defaults, options, picker)
  picker = picker or config.options.picker

  local function api_options()
    if picker == "telescope" then
      return require("telescope.zk.util").note_picker_api_options
    elseif picker == "fzf" then
      return require("zk.fzf").note_picker_api_options
    else
      error(invalid_picker(picker))
    end
  end

  return vim.tbl_deep_extend("force", api_options(), defaults or {}, options or {})
end

function M.tag_picker(tags, title, cb, picker)
  picker = picker or config.options.picker
  title = title or "Zk Tags"
  if picker == "telescope" then
    require("telescope.zk.util").show_tag_picker(tags, { prompt_title = title }, cb)
  elseif picker == "fzf" then
    require("zk.fzf").show_tag_picker(tags, { "--header=" .. title }, cb)
  else
    invalid_picker(picker)
  end
end

function M.make_tag_picker_api_options(defaults, options, picker)
  picker = picker or config.options.picker

  local function api_options()
    if picker == "telescope" then
      return require("telescope.zk.util").tag_picker_api_options
    elseif picker == "fzf" then
      return require("zk.fzf").tag_picker_api_options
    else
      error(invalid_picker(picker))
    end
  end

  return vim.tbl_deep_extend("force", api_options(), defaults or {}, options or {})
end

return M
