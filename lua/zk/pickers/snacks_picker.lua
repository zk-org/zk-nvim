local M = {}
local H = {}

local Snacks = require("snacks")
local snacks_picker = require("snacks.picker")
local snacks_format = require("snacks.picker.format")
local util = require("zk.util")
local api = require("zk.api")
local uv = vim.uv or vim.loop
local notes_cache = {}

-- See https://zk-org.github.io/zk/tips/editors-integration.html#zk-list --> Expand section `2`
M.zk_api_select = { "title", "path" } -- TODO: Can be modify now / Should be included in args's opts?

M.show_note_picker = function(notes, opts, cb)
  notes = vim.tbl_map(function(note)
    local title = note.title or note.path
    return { text = title, file = note.absPath, value = note }
  end, notes)
  H.item_picker(notes, opts, cb)
end

M.show_grep_picker = function(opts, cb)
  local function index_notes_by_path(notes)
    local tbl = {}
    for _, note in ipairs(notes) do
      tbl[note.path] = note
    end
    return tbl
  end

  local picker_opts = vim.tbl_deep_extend("force", {
    format = "zk",
    cwd = opts.notebook_path,
    title = opts.title or "Zk Grep",
    sort = { fields = { "score:desc", "idx" } },
  }, opts.snacks_picker or {})

  api.list(picker_opts.cwd, { select = M.zk_api_select }, function(err, notes)
    if not err then
      notes_cache = index_notes_by_path(notes)
      Snacks.picker.grep(picker_opts, cb)
    end
  end)
end

M.show_tag_picker = function(tags, opts, cb)
  opts.snacks_picker = opts.snacks_picker or {}
  opts.snacks_picker =
    vim.tbl_deep_extend("keep", { preview = "preview", layout = { preview = false } }, opts.snacks_picker)
  local width = H.max_note_count(tags)
  tags = vim.tbl_map(function(tag)
    local padded_count = H.pad(tag.note_count, width)
    return {
      text = string.format(" %s  %s", padded_count, tag.name),
      value = tag,
      preview = { text = string.format("%s notes for #%s tag", tag.note_count, tag.name) },
    }
  end, tags)
  H.item_picker(tags, opts, cb)
end

-- Create a new function that extends builtin `F.filename` with YAML frontmatter title.
-- https://github.com/folke/snacks.nvim/blob/main/lua/snacks/picker/format.lua
---@param item snacks.picker.Item
function snacks_format.zk_filename(item, picker)
  local fullpath = vim.fs.joinpath(item.cwd, item.file)
  ---@type snacks.picker.Highlight[]
  local ret = {}
  if not item.file then
    return ret
  end
  local path = Snacks.picker.util.path(item) or item.file
  path =
    Snacks.picker.util.truncpath(path, picker.opts.formatters.file.truncate or 40, { cwd = picker:cwd() })
  local name, cat = path, "file"
  if item.buf and vim.api.nvim_buf_is_loaded(item.buf) then
    name = vim.bo[item.buf].filetype
    cat = "filetype"
  elseif item.dir then
    cat = "directory"
  end

  if picker.opts.icons.files.enabled ~= false then
    local icon, hl = Snacks.util.icon(name, cat, {
      fallback = picker.opts.icons.files,
    })
    if item.dir and item.open then
      icon = picker.opts.icons.files.dir_open
    end
    icon = Snacks.picker.util.align(icon, picker.opts.formatters.file.icon_width or 2)
    ret[#ret + 1] = { icon, hl, virtual = true }
  end

  local base_hl = item.dir and "SnacksPickerDirectory" or "SnacksPickerFile"
  local function is(prop)
    local it = item
    while it do
      if it[prop] then
        return true
      end
      it = it.parent
    end
  end

  if is("ignored") then
    base_hl = "SnacksPickerPathIgnored"
  elseif is("hidden") then
    base_hl = "SnacksPickerPathHidden"
  elseif item.filename_hl then
    base_hl = item.filename_hl
  end
  local dir_hl = "SnacksPickerDir"

  print("path: " .. path)
  local note = notes_cache[path]
  if note and note.title then
    ret[#ret + 1] = { tostring(note.title), base_hl }
  else
    if picker.opts.formatters.file.filename_only then
      path = vim.fn.fnamemodify(item.file, ":t")
      ret[#ret + 1] = { path, base_hl, field = "file" }
    else
      local dir, base = path:match("^(.*)/(.+)$")
      if base and dir then
        if picker.opts.formatters.file.filename_first then
          ret[#ret + 1] = { base, base_hl, field = "file" }
          ret[#ret + 1] = { " " }
          ret[#ret + 1] = { dir, dir_hl, field = "file" }
        else
          ret[#ret + 1] = { dir .. "/", dir_hl, field = "file" }
          ret[#ret + 1] = { base, base_hl, field = "file" }
        end
      else
        ret[#ret + 1] = { path, base_hl, field = "file" }
      end
    end
  end

  if item.pos and item.pos[1] > 0 then
    ret[#ret + 1] = { ":", "SnacksPickerDelim" }
    ret[#ret + 1] = { tostring(item.pos[1]), "SnacksPickerRow" }
    if item.pos[2] > 0 then
      ret[#ret + 1] = { ":", "SnacksPickerDelim" }
      ret[#ret + 1] = { tostring(item.pos[2]), "SnacksPickerCol" }
    end
  end
  ret[#ret + 1] = { " " }
  if item.type == "link" then
    local real = uv.fs_realpath(item.file)
    local broken = not real
    real = real or uv.fs_readlink(item.file)
    if real then
      ret[#ret + 1] = { "-> ", "SnacksPickerDelim" }
      ret[#ret + 1] =
        { Snacks.picker.util.truncpath(real, 20), broken and "SnacksPickerLinkBroken" or "SnacksPickerLink" }
      ret[#ret + 1] = { " " }
    end
  end
  return ret
end

-- Add 'zk' format
Snacks.picker.format["zk"] = function(item, picker)
  local ret = {}
  if not item.file then
    return ret
  end
  vim.list_extend(ret, snacks_format.zk_filename(item, picker))
  if item.line then
    Snacks.picker.highlight.format(item, item.line, ret)
    table.insert(ret, { " " })
  end
  return ret
end

H.item_picker = function(items, opts, cb)
  opts = opts or {}
  local picker_opts = vim.tbl_deep_extend("force", {
    items = items,
    format = "text",
    sort = { fields = { "score:desc", "idx" } },
    confirm = function(picker, item)
      picker:close()
      if not opts.multi_select then
        cb(item.value)
      else
        cb(vim.tbl_map(function(i)
          return i.value
        end, picker:selected({ fallback = true })))
      end
    end,
  }, opts.snacks_picker or {})
  snacks_picker.pick(opts.title, picker_opts)
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
