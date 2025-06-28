local M = {}

local H = {}

local snacks = require('snacks')
local snacks_picker = require("snacks.picker")
local zk_util = require('zk.util')
local uv = vim.uv or vim.loop
local F = require("snacks.picker.format")


M.note_picker_list_api_selection = { "title", "path", "absPath" }

M.show_note_picker = function(notes, opts, cb)
  notes = vim.tbl_map(function(note)
    local title = note.title or note.path
    return { text = title, file = note.absPath, value = note }
  end, notes)
  H.item_picker(notes, opts, cb)
end

-- local snacks = require("snacks")
-- snacks.picker.format["my_format"] = function(item, picker)
--   --@type snacks.picker.Highlight[]
--   local ret = {}
--   local F = require('snacks.picker.format')
--   -- snacks.picker.highlight.format(item, item.line, ret)
--   -- table.insert(ret, { " " })
--   if item.label then
--     ret[#ret + 1] = { item.label, "SnacksPickerLabel" }
--     ret[#ret + 1] = { " ", virtual = true }
--   end
--
--   if item.parent then
--     vim.list_extend(ret, F.tree(item, picker))
--   end
--
--   if item.status then
--     vim.list_extend(ret, F.file_git_status(item, picker))
--   end
--
--   if item.severity then
--     vim.list_extend(ret, F.severity(item, picker))
--   end
--
--   vim.list_extend(ret, F.filename(item, picker))
--
--   if item.comment then
--     table.insert(ret, { item.comment, "SnacksPickerComment" })
--     table.insert(ret, { " " })
--   end
--
--   if item.line then
--     snacks.picker.highlight.format(item, item.line, ret)
--     table.insert(ret, { " " })
--   end
--   print('\nmy_format: \n' .. vim.inspect(ret))
--   return item
-- end

-- function M.file(item, picker)
--   local F = require('snacks.picker.format')
--   ---@type snacks.picker.Highlight[]
--   local ret = {}

-- TODO: 一番左にアイコンを表示
-- TODO: line:col も表示
-- TODO: file名は非表示

-- TODO: REMOVE after rebase from `buf_name_from_yaml` branch
-- local function read_file(path)
--   local fd = uv.fs_open(path, "r", 438)
--   if not fd then return {} end
--   local stat = uv.fs_fstat(fd)
--   local content = uv.fs_read(fd, stat.size, 0)
--   uv.fs_close(fd)
--   if not content then return {} end
--   return vim.split(content, "\n", { plain = true })
-- end
--
-- local function fetch_yaml(lines)
--   local lyaml = require("lyaml")
--   local text = table.concat(lines, "\n")
--   local yaml_content = text:match("^%-%-%-%s*\n(.-)\n%-%-%-")
--   if not yaml_content then return nil, "No YAML found" end
--   local ok, res = pcall(lyaml.load, yaml_content)
--   if not ok then return nil, "YAML parse error" end
--   return res
-- end


---@param item snacks.picker.Item
function F.zk_filename(item, picker)
  local path = vim.fs.joinpath(item.cwd, item.file)
  local lines = zk_util.read_file(path)
  local yaml = zk_util.fetch_yaml(lines)
  ---@type snacks.picker.Highlight[]
  local ret = {}
  if not item.file then
    return ret
  end
  local path = Snacks.picker.util.path(item) or item.file
  path = Snacks.picker.util.truncpath(path, picker.opts.formatters.file.truncate or 40, { cwd = picker:cwd() })
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


  if yaml then
    if yaml.title then
      ret[#ret+1] = { tostring(yaml.title), base_hl }
      -- ret[#ret+1] = { " " }
    end
    -- TODO: Tag を追加したいときはこれ
    -- if yaml.tags then
    --   ret[#ret+1] = { "(" .. table.concat(yaml.tags, ", ") .. ")", "Comment" }
    --   ret[#ret+1] = { "  " }
    -- end
  else
    -- ret[#ret+1] = { item.file, "Comment" }
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

-- zk_filename を使う前。削除していい
-- require("snacks").picker.format["zk"] = function(item, picker)
--   local ret = {}
--   if not item.file then return ret end
--   local path = vim.fs.joinpath(item.cwd, item.file)
--   local lines = zk_util.read_file(path)
--   local yaml = zk_util.fetch_yaml(lines)
--   if not yaml then
--     ret[#ret+1] = { item.file, "Comment" }
--   else
--     if yaml.title then
--       ret[#ret+1] = { tostring(yaml.title), "Title" }
--       ret[#ret+1] = { "  " }
--     end
--     -- TODO: Tag を追加したいときはこれ
--     -- if yaml.tags then
--     --   ret[#ret+1] = { "(" .. table.concat(yaml.tags, ", ") .. ")", "Comment" }
--     --   ret[#ret+1] = { "  " }
--     -- end
--   end
--   vim.list_extend(ret, F.zk_filename(item, picker)) -- 通常のファイル表示も追加 TODO: ここで、どっかで追加したカスタムの linecol ? 関数を呼び出すこと
--   if item.line then
--     require('snacks').picker.highlight.format(item, item.line, ret)
--     table.insert(ret, { " " })
--   end
--   return ret
-- end

snacks.picker.format["zk"] = function(item, picker)
  local ret = {}
  if not item.file then return ret end
  -- local path = vim.fs.joinpath(item.cwd, item.file)
  -- local lines = zk_util.read_file(path)
  -- local yaml = zk_util.fetch_yaml(lines)
  -- if not yaml then
  --   ret[#ret+1] = { item.file, "Comment" }
  -- else
  --   if yaml.title then
  --     ret[#ret+1] = { tostring(yaml.title), "Title" }
  --     ret[#ret+1] = { "  " }
  --   end
  --   -- TODO: Tag を追加したいときはこれ
  --   -- if yaml.tags then
  --   --   ret[#ret+1] = { "(" .. table.concat(yaml.tags, ", ") .. ")", "Comment" }
  --   --   ret[#ret+1] = { "  " }
  --   -- end
  -- end
  vim.list_extend(ret, F.zk_filename(item, picker))
  if item.line then
    snacks.picker.highlight.format(item, item.line, ret) -- line でも text でも一緒
    -- require('snacks').picker.highlight.format(item, item.text, ret)
    table.insert(ret, { " " })
  end
  return ret
end

M.show_note_grep_picker = function(notes, opts, cb)
  local cur_path = vim.api.nvim_buf_get_name(0)
  local notebook_root = zk_util.notebook_root(cur_path)
  local grep_opts = vim.tbl_deep_extend("force", {
    format = "zk", -- 'file'
    cwd = notebook_root,
    sort = { fields = { "score:desc", "idx" } },
    confirm = function(picker, item)
      picker:close()
      if not opts.multi_select then
        cb(item)
      else
        cb(picker:selected({ fallback = true }))
      end
    end,
    -- TODO: できるかな？
    transform = function(item)
      local file, line, col, text = item.text:match("^(.+):(%d+):(%d+):(.*)$")
      if not file then
        if not item.text:match("WARNING") then
          Snacks.notify.error("invalid grep output:\n" .. item.text)
        end
        return false
      else
        local path = vim.fs.joinpath(item.cwd,item.file)
        local lines = zk_util.read_file(path)
        local yaml = zk_util.fetch_yaml(lines)
        -- item.text = (yaml and yaml.title or file) .. ':' .. line .. ':' .. col .. ' ' .. text
        item.text = text
        item.file = file
        item.pos = { tonumber(line), tonumber(col) - 1 }
        item.title = yaml and yaml.title or ''
      end
    end,
    matcher = {
      on_match = function(matcher, item)
        -- -- if matcher.pattern == "" then return end -- 空文字ならスキップ
        -- -- local positions = matcher:positions(item)
        -- local positions = matcher:positions({
        --   text = item.text,
        --   title = item.title,
        --   idx = item.idx,
        --   score = item.score,
        -- })
        -- print(vim.inspect(matcher))
        -- print(vim.inspect(positions))
        -- print(vim.inspect(item))
        -- if positions.title and not positions.text then
        --   item.score = 0 -- YAML title のみマッチは除外
        -- end
        -- if matcher:empty() then return end -- 検索語が空なら処理しない

        -- local positions = matcher:positions({
        --   text = item.text,
        --   title = item.title,
        --   idx = item.idx,
        --   score = item.score,
        -- })
        -- local mods = matcher.Mods

        --
        -- if positions.title and not positions.text then
        --   item.score = 0 -- YAML title のみマッチは除外
        -- end

        -- print(matcher.positions.text)

        -- print('matcher:\n' .. vim.inspect(matcher))
        -- print('positions:\n' .. vim.inspect(positions))
        -- print('Mods:\n' .. vim.inspect(mods))
        -- print('item:\n' .. vim.inspect(item))
        -- print('matcher:\n' .. vim.inspect(matcher))
      end
    },
    -- matcher = nil
  }, opts.snacks_picker or {})
  snacks.picker.grep(grep_opts, cb)
end

-- -- Without YAML title version
-- M.show_note_grep_picker = function(notes, opts, cb)
--   local cur_path = vim.api.nvim_buf_get_name(0)
--   local notebook_root = zk_util.notebook_root(cur_path)
--   local grep_opts = vim.tbl_deep_extend("force", {
--     format = "file",
--     cwd = notebook_root,
--     sort = { fields = { "score:desc", "idx" } },
--     confirm = function(picker, item)
--       picker:close()
--       if not opts.multi_select then
--         cb(item)
--       else
--         cb(picker:selected({ fallback = true }))
--       end
--     end,
--   }, opts.snacks_picker or {})
--   snacks.picker.grep(grep_opts, cb)
-- end

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
