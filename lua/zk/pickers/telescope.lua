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
local api = require("zk.api")
local notes_cache = {}

local M = {}

-- See https://zk-org.github.io/zk/tips/editors-integration.html#zk-list --> Expand section `2`
M.zk_api_select = { "title", "absPath", "path" } -- TODO: Can be modify now / Should be included in args's opts?

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
          actions.close(prompt_bufnr)
          vim.schedule(function()
            require("zk").new({ title = prompt })
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

function M.make_grep_sorter(opts)
  -- currently highlighter_only (no sorting)
  opts = opts or {}
  local fzy = opts.fzy_mod or require("telescope.algos.fzy")

  return require("telescope.sorters").Sorter:new({
    scoring_function = function()
      return 1
    end,

    highlighter = function(_, prompt, display)
      local entry_text = display:match("^.-%s%d+:%d+%s(.*)$") or display
      local prefix_len = #display - #entry_text
      local relative_positions = fzy.positions(prompt, entry_text)
      local absolute_positions = {}
      for i, pos in ipairs(relative_positions) do
        absolute_positions[i] = pos + prefix_len
      end
      return absolute_positions
    end,
  })
end

function M.create_grep_entry_maker(collection)
  local displayer = entry_display.create({
    separator = " ",
    items = { {}, {}, {} },
  })

  return function(line)
    local filename, lnum, col, text = string.match(line, "^(.-):(%d+):(%d+):(.*)$")
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
          { tostring(entry.lnum) .. ":" .. tostring(entry.col), "TelescopeResultsLineNr" },
          { entry.text, "TelescopeResultsNormal" },
        })
      end,
      -- title = title,
      title = notes_cache[filename] and notes_cache[filename].title or title,
      value = {
        filename = filename,
        lnum = lnum,
        col = col,
        text = text,
        title = title,
        absPath = filename,
      },
    }
  end
end

function M.show_grep_picker(options, cb)
  local function index_notes_by_path(notes)
    local tbl = {}
    for _, note in ipairs(notes) do
      tbl[note.absPath] = note
    end
    return tbl
  end
  options = options or {}
  local path = vim.api.nvim_buf_get_name(0)
  local root = (path ~= "") and util.notebook_root(path)
    or util.notebook_root(vim.fn.getcwd())
    or vim.fn.getenv("ZK_NOTEBOOK_DIR")
  local collection = {}

  local telescope_options =
    vim.tbl_extend("force", { prompt_title = options.title or "Zk Grep" }, options.telescope or {})

  -- for _, note in ipairs(notes) do
  --   collection[note.absPath] = note.title or note.path
  -- end

  local grep_finder = finders.new_job(function(prompt)
    if not prompt or prompt == "" then
      return nil
    end
    return {
      "rg",
      "--vimgrep",
      "--no-heading",
      "--smart-case",
      prompt,
      root,
    }
  end, M.create_grep_entry_maker(collection))

  api.list(root, { select = M.zk_api_select }, function(err, notes)
    if not err then
      notes_cache = index_notes_by_path(notes)
      -- Snacks.picker.grep(picker_opts, cb)
      pickers
        .new(telescope_options, {
          finder = grep_finder,
          previewer = conf.grep_previewer(options),
          sorter = M.make_grep_sorter(options),
          attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
              if options.multi_select then
                local selection = {}
                action_utils.map_selections(prompt_bufnr, function(entry, _)
                  table.insert(selection, entry.value)
                end)
                if vim.tbl_isempty(selection) then
                  table.insert(selection, action_state.get_selected_entry().value)
                end
                actions.close(prompt_bufnr)
                cb(selection)
              else
                local entry = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                cb(entry and entry.value or nil)
              end
            end)
            return true
          end,
        })
        :find()
    end
  end)
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
