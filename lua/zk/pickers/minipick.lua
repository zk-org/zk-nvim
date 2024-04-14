local M = {}
local H = {}
local minipick = require("mini.pick")

M.note_picker_list_api_selection = { "title", "path", "absPath" }

M.show_note_picker = function(notes, opts, cb)
  notes = vim.tbl_map(function(note)
    local title = note.title or note.path
    return { text = title, path = note.absPath, value = note }
  end, notes)
  H.item_picker(notes, opts, cb)
end

M.show_tag_picker = function(tags, opts, cb)
  local width = H.max_note_count(tags)
  tags = vim.tbl_map(function(tag)
    local padded_count = H.pad(tag.note_count, width)
    return {
      text = string.format(" %s │ %s", padded_count, tag.name),
      value = tag,
    }
  end, tags)
  H.item_picker(tags, opts, cb)
end

H.item_picker = function(items, opts, cb)
  opts = opts or {}
  local minipick_opts = vim.tbl_deep_extend("force", {
    window = {
      prompt_prefix = opts.title .. "> ",
    },
    source = {
      items = items,
      name = opts.title,

      choose = function(selected_item) -- item guaranteed to be non-nil
        local target_window = minipick.get_picker_state().windows.target
        vim.api.nvim_win_call(target_window, function()
          cb(opts.multi_select and { selected_item.value } or selected_item.value)
        end)
        return nil
      end,

      choose_marked = function(selected_items) -- could be empty table
        if opts.multi_select and not vim.tbl_isempty(selected_items) then
          local target_window = minipick.get_picker_state().windows.target
          vim.api.nvim_win_call(target_window, function()
            cb(vim.tbl_map(function(item)
              return item.value
            end, selected_items))
          end)
        end
        return nil
      end,
    },
  }, opts.minipick or {})

  minipick.start(minipick_opts)
end

H.max_note_count = function(tags)
  local max_count = 0
  for _, t in ipairs(tags) do
    max_count = math.max(max_count, t.note_count)
  end
  return vim.fn.strchars(tostring(max_count))
end

H.pad = function(text, width)
  local text_width = vim.fn.strchars(text)
  return string.rep(" ", width - text_width) .. text
end

return M
