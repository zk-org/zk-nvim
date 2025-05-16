local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local action_utils = require("telescope.actions.utils")
local entry_display = require("telescope.pickers.entry_display")
local previewers = require("telescope.previewers")
local sorters = require("telescope.sorters")
local util = require("zk.util")

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
      conf.buffer_previewer_maker(entry.value.absPath, self.state.bufnr, {
        bufname = entry.value.title or entry.value.path,
        winid = self.state.winid,
      })
    end,
  })
end

function M.show_note_picker(notes, options, cb)
  options = options or {}
  local telescope_options = vim.tbl_extend("force", { prompt_title = options.title }, options.telescope or {})

  pickers
    .new(telescope_options, {
      finder = finders.new_table({
        results = notes,
        entry_maker = M.create_note_entry_maker(options),
      }),
      sorter = conf.file_sorter(options),
      previewer = M.make_note_previewer(),
      attach_mappings = function(prompt_bufnr)
        -- TODO: add an action here to grep the currently displayed notes with ZkGrep.
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
        return true
      end,
    })
    :find()
end

function M.show_note_grep_picker(opts)
  local path = vim.api.nvim_buf_get_name(0)
  local root = (path ~= "") and util.notebook_root(path) or util.notebook_root(vim.fn.getcwd())
  local collection = {}

  -- Collect title info
  require("zk.api").list(root, { select = { "title", "path", "absPath" } }, function(_, notes)
    for _, note in ipairs(notes) do
      collection[note.absPath] = note.title or note.path
    end
  end)

  local displayer = entry_display.create({
    separator = " ",
    items = { {}, {}, {}, {}, }, -- title, lnum, col, text
  })

  local entry_maker = function(line)
    local filename, lnum, col, text = string.match(line, "([^:]+):(%d+):(%d+):(.*)")
    lnum, col = tonumber(lnum), tonumber(col)
    local title = collection[filename] or vim.fn.fnamemodify(filename, ":t")
    return {
      filename = filename,
      lnum = lnum,
      col = col,
      text = text,
      ordinal = title .. ":" .. lnum .. ":" .. col .. ":" .. text,
      display = function(entry)
        return displayer({
          { entry.title, "TelescopeResultsIdentifier" },
          { tostring(entry.lnum) .. ':' .. tostring(entry.col), "TelescopeResultsLineNr"},
          { entry.text, "TelescopeResultsNormal" },
        })
      end,
      title = title,
      value = {
        filename = filename,
        lnum = lnum,
        col = col,
        text = text,
        title = title,
      },
    }
  end

  local grep_finder = finders.new_job(function(prompt)
    if not prompt or prompt == "" then return nil end
    return {
      "rg",
      "--vimgrep",
      "--no-heading",
      "--smart-case",
      prompt,
      root,
    }
  end, entry_maker)

  pickers.new(opts, {
    prompt_title = "Zk Grep",
    finder = grep_finder,
    previewer = conf.grep_previewer(opts),
    sorter = sorters.highlighter_only(opts),
  }):find()
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
