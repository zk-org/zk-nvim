local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local action_utils = require("telescope.actions.utils")
local putils = require("telescope.previewers.utils")
local entry_display = require("telescope.pickers.entry_display")
local previewers = require("telescope.previewers")
local config = require("zk.config")

local M = {}

M.note_picker_list_api_selection = { "title", "absPath", "path" }

function M.create_note_entry_maker(_)
  return function(note)
    local title = note.title or note.path
    return {
      value = note,
      path = note.absPath,
      display = title,
      ordinal = title,
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
      conf.buffer_previewer_maker(
        entry.value.absPath,
        self.state.bufnr,
        { bufname = entry.value.title or entry.value.path }
      )
    end,
  })
end

function M.capture_cursor_state()
  local pos = vim.api.nvim_win_get_cursor(0)
  return {
    bufnr = vim.api.nvim_get_current_buf(),
    row = pos[1] - 1,
    col = pos[2],
  }
end

function M.insert_links_at_cursor(cursor, entries)
  for i, entry in pairs(entries) do
    entries[i] = string.format("[%s](%s)", entry.title, entry.path)
  end
  vim.api.nvim_buf_set_text(cursor.bufnr, cursor.row, cursor.col, cursor.row, cursor.col, entries)
end

function M.show_note_picker(notes, options, cb)
  options = options or {}
  local telescope_options = vim.tbl_extend("force", { prompt_title = options.title }, options.telescope or {})

  -- before telescope buffer takes over
  local cursor = M.capture_cursor_state()

  pickers.new(telescope_options, {
    finder = finders.new_table({
      results = notes,
      entry_maker = M.create_note_entry_maker(options),
    }),
    sorter = conf.file_sorter(options),
    previewer = M.make_note_previewer(),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        if options.multi_select then
          local selection = {}
          action_utils.map_selections(prompt_bufnr, function(entry, _)
            table.insert(selection, entry.value)
          end)
          if vim.tbl_isempty(selection) then
            selection = { action_state.get_selected_entry().value }
          end
          actions.close(prompt_bufnr)
          cb(selection)
        else
          actions.close(prompt_bufnr)
          cb(action_state.get_selected_entry().value)
        end
      end)


      -- add the option to insert the note as link in current buffer
      local mode = config.options.mappings.telescope_link_note[1]
      local key = config.options.mappings.telescope_link_note[2]
      map(mode, key, function()
        local selection = {}
        if options.multi_select then
          action_utils.map_selections(prompt_bufnr, function(entry, _)
            table.insert(selection, entry.value)
          end)
        else
          selection = { action_state.get_selected_entry().value }
        end
        if vim.tbl_isempty(selection) then
          selection = { action_state.get_selected_entry().value }
        end
        M.insert_links_at_cursor(cursor, selection)
        actions.close(prompt_bufnr)
      end)

      return true
    end,
  }):find()
end

function M.show_tag_picker(tags, options, cb)
  options = options or {}
  local telescope_options = vim.tbl_extend("force", { prompt_title = options.title }, options.telescope or {})

  pickers.new(telescope_options, {
    finder = finders.new_table({
      results = tags,
      entry_maker = M.create_tag_entry_maker(options),
    }),
    sorter = conf.generic_sorter(options),
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        if options.multi_select then
          local selection = {}
          action_utils.map_selections(prompt_bufnr, function(entry, _)
            table.insert(selection, entry.value)
          end)
          if vim.tbl_isempty(selection) then
            selection = { action_state.get_selected_entry().value }
          end
          actions.close(prompt_bufnr)
          cb(selection)
        else
          cb(action_state.get_selected_entry().value)
        end
      end)
      return true
    end,
  }):find()
end

return M
