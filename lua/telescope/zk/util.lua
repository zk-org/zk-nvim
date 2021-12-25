local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local action_utils = require("telescope.actions.utils")
local putils = require("telescope.previewers.utils")
local entry_display = require("telescope.pickers.entry_display")
local previewers = require("telescope.previewers")

local M = {}

M.note_picker_api_options = { select = { "title", "absPath", "rawContent" }, sort = { "created" } }

M.tag_picker_api_options = {
  sort = { "note-count" },
}

function M.create_note_entry_maker(_)
  return function(note)
    return {
      value = note,
      path = note.absPath,
      display = note.title,
      ordinal = note.title,
    }
  end
end

function M.create_tag_entry_maker(opts)
  return function(tag)
    local displayer = entry_display.create({
      separator = " ",
      items = {
        { width = opts.note_count_width or 4 },
        { remaining = true },
      },
    })
    local make_display = function(e)
      return displayer({
        { e.value.note_count, "TelescopeResultsNumber" },
        e.value.name,
      })
    end
    return {
      value = tag,
      display = make_display,
      ordinal = tag.name,
    }
  end
end

function M.make_note_previewer()
  return previewers.new_buffer_previewer({
    define_preview = function(self, entry)
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(entry.value.rawContent, "\n"))
      putils.highlighter(self.state.bufnr, "markdown")
    end,
  })
end

function M.show_note_picker(notes, opts)
  opts = vim.tbl_extend("keep", opts or {}, { prompt_title = "Zk Notes" })
  pickers.new(opts, {
    finder = finders.new_table({
      results = notes,
      entry_maker = M.create_note_entry_maker(opts),
    }),
    sorter = conf.file_sorter(opts),
    previewer = M.make_note_previewer(),
  }):find()
end

function M.show_tag_picker(tags, opts, cb)
  opts = vim.tbl_extend("keep", opts or {}, { prompt_title = "Zk Tags" })
  pickers.new(opts, {
    finder = finders.new_table({
      results = tags,
      entry_maker = M.create_tag_entry_maker(opts),
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        local selection = {}
        action_utils.map_selections(prompt_bufnr, function(entry, _)
          table.insert(selection, entry.value.name)
        end)

        if vim.tbl_isempty(selection) then
          selection = { action_state.get_selected_entry().value.name }
        end

        actions.close(prompt_bufnr)

        cb(selection)
      end)
      return true
    end,
  }):find()
end

return M
