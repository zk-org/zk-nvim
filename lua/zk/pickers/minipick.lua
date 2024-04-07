local M = {}
local H = {}
local minipick = require("mini.pick")

M.note_picker_list_api_selection = { "title", "path", "absPath" }

M.show_note_picker = function(notes, opts, cb)
  notes = vim.tbl_map(function(n)
    return { text = n.title, path = n.absPath, note = n }
  end, notes)

  opts = opts or {}
  local minipick_opts = vim.tbl_deep_extend("force", {
    source = {
      items = notes,
      name = opts.title,
      choose = function(_)
        return nil
      end,
    },
    window = {
      prompt_prefix = opts.title .. "> ",
    },
  }, opts.minipick or {})

  local item = minipick.start(minipick_opts)
  if item ~= nil then
    cb(opts.multi_select and { item.note } or item.note)
  end
end

M.show_tag_picker = function(tags, opts, cb)
  tags = vim.tbl_map(function(t)
    local padded_cnt = H.ensure_text_width(t.note_count, opts.note_count_width or 4)
    return {
      text = string.format("%s │ %s", padded_cnt, t.name),
      tag = t,
    }
  end, tags)

  opts = opts or {}
  local minipick_opts = vim.tbl_deep_extend("force", {
    source = {
      items = tags,
      name = opts.title,
      choose = function(_)
        return nil
      end,
    },
    window = {
      prompt_prefix = opts.title .. "> ",
    },
  }, opts.minipick or {})

  local item = minipick.start(minipick_opts)
  if item ~= nil then
    cb(opts.multi_select and { item.tag } or item.tag)
  end
end

-- From mini.extras
H.ensure_text_width = function(text, width)
  local text_width = vim.fn.strchars(text)
  if text_width <= width then
    return string.rep(" ", width - text_width) .. text
  end
  return "…" .. vim.fn.strcharpart(text, text_width - width + 1, width - 1)
end

return M
