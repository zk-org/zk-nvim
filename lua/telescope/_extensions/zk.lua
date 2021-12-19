local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local action_utils = require("telescope.actions.utils")
local putils = require("telescope.previewers.utils")
local entry_display = require("telescope.pickers.entry_display")
local previewers = require("telescope.previewers")
local zk = require("zk")

local function make_note_args(opts)
  return vim.tbl_extend("force", { select = { "title", "absPath", "rawContent" }, sort = { "created" } }, opts or {})
end

local function make_tag_args(opts)
  return vim.tbl_extend("force", { sort = { "note-count" } }, opts or {})
end

local function make_note_entry(note)
  return {
    value = note,
    path = note.absPath,
    display = note.title,
    ordinal = note.title,
  }
end

local function make_note_previewer()
  return previewers.new_buffer_previewer({
    define_preview = function(self, entry)
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(entry.value.rawContent, "\n"))
      putils.highlighter(self.state.bufnr, "markdown")
    end,
  })
end

local function _list_notes(opts, defaults, zk_args)
  zk.list(opts.path, zk_args, function(notes)
    pickers.new(
      opts,
      vim.tbl_extend("error", {
        finder = finders.new_table({
          results = notes,
          entry_maker = make_note_entry,
        }),
        sorter = conf.file_sorter(opts),
        previewer = make_note_previewer(),
      }, defaults)
    ):find()
  end)
end

local function list_notes(opts)
  opts = opts or {}
  _list_notes(opts, { prompt_title = "Zk Notes" }, make_note_args())
end

local function list_links_to_current_note(opts)
  opts = opts or {}
  _list_notes(opts, { prompt_title = "Zk Backlinks" }, make_note_args({ linkTo = { vim.api.nvim_buf_get_name(0) } }))
end

local function list_tags(opts)
  opts = opts or {}
  zk.tag.list(opts.path, make_tag_args(), function(tags)
    pickers.new(opts, {
      prompt_title = "Zk Tags",
      finder = finders.new_table({
        results = tags,
        entry_maker = function(entry)
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
            value = entry,
            display = make_display,
            ordinal = entry.name,
          }
        end,
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

          _list_notes(opts, { prompt_title = "Zk Notes for tag(s) " .. vim.inspect(selection) }, { tags = selection })
        end)
        return true
      end,
    }):find()
  end)
end

return require("telescope").register_extension({
  exports = {
    notes = list_notes,
    backlinks = list_links_to_current_note,
    tags = list_tags,
  },
})
