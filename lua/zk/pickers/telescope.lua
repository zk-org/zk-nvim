local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local action_utils = require("telescope.actions.utils")
local entry_display = require("telescope.pickers.entry_display")
local previewers = require("telescope.previewers")

local config = require("zk.config")
local display_opts = config.options.picker_options.display

local M = {}

M.note_picker_list_api_selection = { "title", "absPath", "path" }

function M.custom_note_display(e)
  local items_layout = {}
  local items_displayer = {}

  for _, item in ipairs(display_opts.entry) do
    local name, width, hl = unpack(item)

    if width == "auto" then
      table.insert(items_layout, { width = #(e.value[name] or "") or 0 })
    elseif type(width) == "number" then
      table.insert(items_layout, { width = width })
    else
      table.insert(items_layout, { remaining = true })
    end

    if hl then
      table.insert(items_displayer, { e.value[name] or "", hl })
    else
      table.insert(items_displayer, e.value[name] or "")
    end
  end

  local displayer = entry_display.create({
    separator = display_opts.separator,
    items = items_layout,
  })

  return displayer(items_displayer)
end

M.custom_note_ordinal = function(note)
  local result = {}
  for _, field in ipairs(display_opts.ordinal) do
    table.insert(result, note[field])
  end
  return table.concat(result, " ")
end

function M.create_note_entry_maker(_)
  return function(note)
    local title = note.title or note.path
    return {
      value = note,
      path = note.absPath,
      display = display_opts == nil and title or M.custom_note_display,
      ordinal = display_opts == nil and title or M.custom_note_ordinal(note),
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
      conf.buffer_previewer_maker(entry.value.absPath, self.state.bufnr, {
        bufname = entry.value.title or entry.value.path,
        winid = self.state.winid,
      })
    end,
  })
end

function M.show_note_picker(notes, options, cb)
  options = options or {}
  local telescope_options = vim.tbl_extend(
    "force",
    { prompt_title = options.title },
    options.telescope or { prompt_title = "CTRL-E: create a note with the query as title" }
  )

  pickers
    .new(telescope_options, {
      finder = finders.new_table({
        results = notes,
        entry_maker = M.create_note_entry_maker(options),
      }),
      sorter = conf.file_sorter(options),
      previewer = M.make_note_previewer(),
      attach_mappings = function(prompt_bufnr, mapping)
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
        mapping("i", "<C-e>", function()
          local current_picker = action_state.get_current_picker(prompt_bufnr)
          local prompt = current_picker:_get_prompt()
          options["title"] = prompt
          actions.close(prompt_bufnr)
          vim.schedule(function()
            require("zk").new(options)
          end)
        end)
        mapping("i", "<CR>", function()
          local entry = action_state.get_selected_entry()
          if entry == nil then
            actions.close(prompt_bufnr)
          else
            vim.schedule(function()
              actions.select_default(prompt_bufnr)
            end)
          end
        end)
        return true
      end,
    })
    :find()
end

function M.show_tag_picker(tags, options, cb)
  options = options or {}
  local telescope_options = vim.tbl_extend("force", { prompt_title = options.title }, options.telescope or {})

  pickers
    .new(telescope_options, {
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
    })
    :find()
end

return M
