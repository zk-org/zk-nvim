local M = {}

local delimiter = "\x01"

-- we want can't do vim.fn["fzf#wrap"] because the sink/sinklist funcrefs
-- are reset to vim.NIL when they are converted to Lua
vim.cmd([[
  function! _fzf_wrap_and_run(...)
    call fzf#run(call('fzf#wrap', a:000))
  endfunction
]])

M.note_picker_list_api_selection = { "title", "path", "absPath" }

function M.show_note_picker(notes, options, cb)
  options = options or {}
  vim.fn._fzf_wrap_and_run({
    source = vim.tbl_map(function(v)
      local title = v.title or v.path
      return table.concat({ v.absPath, title }, delimiter)
    end, notes),
    options = vim.list_extend({
      "--delimiter=" .. delimiter,
      "--tiebreak=index",
      "--with-nth=2",
      "--exact",
      "--tabstop=4",
      [[--preview=command -v bat 1>/dev/null 2>&1 && bat -p --color always {1} || cat {1}]],
      "--preview-window=wrap",
      options.title and "--header=" .. options.title or nil,
      options.multi_select and "--multi" or nil,
    }, options.fzf_options or {}),
    sinklist = function(lines)
      local notes_by_path = {}
      for _, note in ipairs(notes) do
        notes_by_path[note.absPath] = note
      end
      local selected_notes = vim.tbl_map(function(line)
        local path = string.match(line, "([^" .. delimiter .. "]+)")
        return notes_by_path[path]
      end, lines)
      if options.multi_select then
        cb(selected_notes)
      else
        cb(selected_notes[1])
      end
    end,
  })
end

function M.show_tag_picker(tags, options, cb)
  options = options or {}
  vim.fn._fzf_wrap_and_run({
    source = vim.tbl_map(function(v)
      return table.concat({ string.format("\x1b[31m%-4d\x1b[0m", v.note_count), v.name }, delimiter)
    end, tags),
    options = vim.list_extend({
      "--delimiter=" .. delimiter,
      "--tiebreak=index",
      "--nth=2",
      "--exact",
      "--tabstop=4",
      "--ansi",
      options.title and "--header=" .. options.title or nil,
      options.multi_select and "--multi" or nil,
    }, options.fzf or {}),
    sinklist = function(lines)
      local tags_by_name = {}
      for _, tag in ipairs(tags) do
        tags_by_name[tag.name] = tag
      end
      local selected_tags = vim.tbl_map(function(line)
        local name = string.match(line, "%d+%s+" .. delimiter .. "(.+)")
        return tags_by_name[name]
      end, lines)
      if options.multi_select then
        cb(selected_tags)
      else
        cb(selected_tags[1])
      end
    end,
  })
end

return M
