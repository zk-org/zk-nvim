local M = {}

local delimiter = "\x01 "

-- we want can't do vim.fn["fzf#wrap"] because the sink/sinklist funcrefs
-- are reset to vim.NIL when they are converted to Lua
vim.cmd([[
  function! _fzf_wrap_and_run(...)
    call fzf#run(call('fzf#wrap', a:000))
  endfunction
]])

M.note_picker_api_options = { select = { "title", "absPath" }, sort = { "created" } }

M.tag_picker_api_options = {
  sort = { "note-count" },
}

function M.show_note_picker(notes, options)
  vim.fn._fzf_wrap_and_run({
    source = vim.tbl_map(function(v)
      return table.concat({ v.absPath, v.title }, delimiter)
    end, notes),
    options = vim.list_extend({
      "--delimiter=" .. delimiter,
      "--tiebreak=index",
      "--with-nth=2",
      "--exact",
      "--tabstop=4",
      "--multi",
      [[--preview=command -v bat 1>/dev/null 2>&1 && bat -p --color always {1} || cat {1}]],
      "--preview-window=wrap",
    }, options or {}),
    sink = function(line)
      local absPath = string.match(line, "([^" .. delimiter .. "]+)")
      vim.cmd("e " .. absPath)
    end,
  })
end

function M.show_tag_picker(tags, options, cb)
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
      "--multi",
      "--ansi",
    }, options or {}),
    sinklist = function(lines)
      tags = vim.tbl_map(function(v)
        return string.match(v, "([^" .. delimiter .. "]+)", 2)
      end, lines)
      cb(tags)
    end,
  })
end

return M
