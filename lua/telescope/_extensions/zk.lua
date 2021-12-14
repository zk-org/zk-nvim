local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local action_utils = require("telescope.actions.utils")
local putils = require("telescope.previewers.utils")
local entry_display = require("telescope.pickers.entry_display")
local previewers = require("telescope.previewers")

local function request_notes(bufnr, options, cb)
  vim.lsp.buf_request(bufnr, "workspace/executeCommand", {
    command = "zk.list",
    arguments = {
      vim.api.nvim_buf_get_name(bufnr),
      vim.tbl_extend("error", { select = { "title", "absPath", "rawContent" } }, options or {}),
    },
  }, function(err, res)
    assert(not err, err)
    if res then
      cb(res)
    end
  end)
end

local function request_tags(bufnr, cb)
  vim.lsp.buf_request(bufnr, "workspace/executeCommand", {
    command = "zk.tag.list",
    arguments = { vim.api.nvim_buf_get_name(bufnr) },
  }, function(err, res)
    assert(not err, err)
    if res then
      cb(res)
    end
  end)
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

local function _list_notes(user_opts, local_opts, lsp_opts)
  request_notes(0, lsp_opts, function(notes)
    pickers.new(
      user_opts,
      vim.tbl_extend("error", {
        finder = finders.new_table({
          results = notes,
          entry_maker = make_note_entry,
        }),
        sorter = conf.file_sorter(user_opts),
        previewer = make_note_previewer(),
      }, local_opts)
    ):find()
  end)
end

local function list_notes(opts)
  _list_notes(opts, { prompt_title = "Zk Notes" }, nil)
end

local function list_links_to_current_note(opts)
  _list_notes(opts, { prompt_title = "Zk Backlinks" }, { linkTo = { vim.api.nvim_buf_get_name(0) } })
end

local function list_tags(opts)
  request_tags(0, function(tags)
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

          _list_notes(opts, { tags = selection })
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
