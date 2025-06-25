local M = {}
local H = {}
local snacks_picker = require("snacks.picker")

M.note_picker_list_api_selection = { "title", "path", "absPath" }

M.show_note_picker = function(notes, opts, cb)
  notes = vim.tbl_map(function(note)
    local title = note.title or note.path
    return { text = title, file = note.absPath, value = note }
  end, notes)
  H.item_picker(notes, opts, cb)
end

local snacks = require("snacks")
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
--
--   -- if item.label then
--   --   ret[#ret + 1] = { item.label, "SnacksPickerLabel" }
--   --   ret[#ret + 1] = { " ", virtual = true }
--   -- end
--   --
--   -- if item.parent then
--   --   vim.list_extend(ret, F.tree(item, picker))
--   -- end
--   --
--   -- if item.status then
--   --   vim.list_extend(ret, F.file_git_status(item, picker))
--   -- end
--   --
--   -- if item.severity then
--   --   vim.list_extend(ret, F.severity(item, picker))
--   -- end
--   --
--   vim.list_extend(ret, F.filename(item, picker))
--   --
--   -- if item.comment then
--   --   table.insert(ret, { item.comment, "SnacksPickerComment" })
--   --   table.insert(ret, { " " })
--   -- end
--
--   if item.line then
--     Snacks.picker.highlight.format(item, item.line, ret)
--     table.insert(ret, { " " })
--     print('\nitem.line: \n' .. vim.inspect(ret))
--   end
--   return ret
-- end

local uv = vim.uv or vim.loop
local F = require("snacks.picker.format")

local function read_file(path)
  local fd = uv.fs_open(path, "r", 438)
  if not fd then return {} end
  local stat = uv.fs_fstat(fd)
  local content = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)
  if not content then return {} end
  return vim.split(content, "\n", { plain = true })
end

local function fetch_yaml(lines)
  local lyaml = require("lyaml")
  local text = table.concat(lines, "\n")
  local yaml_content = text:match("^%-%-%-%s*\n(.-)\n%-%-%-")
  if not yaml_content then return nil, "No YAML found" end
  local ok, res = pcall(lyaml.load, yaml_content)
  if not ok then return nil, "YAML parse error" end
  return res
end

function M.filename_yaml(item, picker)
  local ret = {}

  if not item.file then return ret end
  local path = item.cwd .. "/" .. item.file
  local lines = read_file(path)
  local yaml, err = fetch_yaml(lines)
  if not yaml then
    ret[#ret+1] = { "[No YAML]", "Comment" }
  else
    if yaml.title then
      ret[#ret+1] = { tostring(yaml.title), "Title" }
      ret[#ret+1] = { "  " }
    end
    if yaml.tags then
      ret[#ret+1] = { "(" .. table.concat(yaml.tags, ", ") .. ")", "Comment" }
      ret[#ret+1] = { "  " }
    end
  end

  vim.list_extend(ret, F.filename(item, picker)) -- 通常のファイル表示も追加
  return ret
end

require("snacks").picker.format["filename_yaml"] = M.filename_yaml
-- require('snacks').picker.format["my_format"] = M.file


M.show_note_grep_picker = function(notes, opts, cb)
  -- notes = vim.tbl_map(function(note)
  --   local title = note.title or note.path
  --   return { text = title .. ':100:100:This is code desu yo.', file = note.absPath, value = note }
  -- end, notes)
  -- H.item_picker(notes, opts, cb)

  -- local snacks = require('snacks')
  --
  -- -- notebook rootを取得してcwdに設定
  -- local path = vim.api.nvim_buf_get_name(0)
  -- local notebook_root = require('zk.util').notebook_root(path)
  -- if notebook_root then
  --   opts = opts or {}
  --   opts.cwd = notebook_root
  -- end
  --
  -- -- 通常のgrep pickerを呼び出し
  -- snacks.picker.grep(opts, cb)

  local snacks = require('snacks')
  local cur_path = vim.api.nvim_buf_get_name(0)
  local notebook_root = require('zk.util').notebook_root(cur_path)
  local grep_opts = vim.tbl_deep_extend("force", {
    -- format = "text",
    -- format = "file",
    -- format = "my_format",
    format = "filename_yaml",
    cwd = notebook_root,
    sort = { fields = { "score:desc", "idx" } },
    -- grepの結果処理
    confirm = function(picker, item)
      picker:close()
      if not opts.multi_select then
        cb(item) -- grepの場合はitem自体を渡す
      else
        cb(picker:selected({ fallback = true }))
      end
    end,
    -- できるかな？
    transform = function(item)
      local function read_file(path)
        local f = io.open(path, "r")
        if not f then return nil end
        local content = f:read("*a")
        f:close()
        return vim.split(content, "\n", { plain = true })
      end

      -- このフォークにはこの関数が無いので、一時的に持ってきた
      ---@return table|nil yaml as table
      ---@return string|nil err error message
      function fetch_yaml(lines)
         local lyaml = require('lyaml')

         local text = table.concat(lines, '\n')
         local yaml_start, _ = text:find('^%-%-%-\n(.-)\n%-%-%-', 1)
         if not yaml_start then return nil, 'No YAML front matter found' end

         local yaml_content = text:match('^%-%-%-\n(.-)\n%-%-%-')
         if not yaml_content then return nil, 'Failed to extract YAML content' end

         local success, yaml = pcall(lyaml.load, yaml_content)
         if not success then return nil, 'Failed to parse YAML: ' .. tostring(yaml) end

         return yaml
      end

      -- local cwd = vim.fn.getcwd() -- Asyncではエラー
      -- item.cwd = cwd
      -- item.cwd = '/Users/rio/Projects/terminal/test' -- あれ、cwd は要らないらしい 既に設定済みなのかも
      local file, line, col, text = item.text:match("^(.+):(%d+):(%d+):(.*)$")
      if not file then
        if not item.text:match("WARNING") then
          Snacks.notify.error("invalid grep output:\n" .. item.text)
        end
        return false
      else
        local path = item.cwd .. '/' .. item.file
        -- local lines = vim.fn.readfile(path) -- Async 中は同期処理は呼び出せない
        local lines = read_file(path)
        local yaml = fetch_yaml(lines)
        -- print(vim.inspect(yaml))
        item.text =  (yaml.title or file) .. ':' .. line .. ':' .. col .. ' ' .. text
        item.file = file
        item.pos = { tonumber(line), tonumber(col) - 1 }
        -- print(vim.inspect(item))
      end
    end,
    -- format = function(item, picker)
    --   -- このフォークにはこの関数が無いので、一時的に持ってきた
    --   ---@return table|nil yaml as table
    --   ---@return string|nil err error message
    --   function fetch_yaml(lines)
    --      local lyaml = require('lyaml')
    --
    --      local text = table.concat(lines, '\n')
    --      local yaml_start, _ = text:find('^%-%-%-\n(.-)\n%-%-%-', 1)
    --      if not yaml_start then return nil, 'No YAML front matter found' end
    --
    --      local yaml_content = text:match('^%-%-%-\n(.-)\n%-%-%-')
    --      if not yaml_content then return nil, 'Failed to extract YAML content' end
    --
    --      local success, yaml = pcall(lyaml.load, yaml_content)
    --      if not success then return nil, 'Failed to parse YAML: ' .. tostring(yaml) end
    --
    --      return yaml
    --   end
    --   -- -- itemの構造を確認してファイル名を取得
    --   -- print('item (Before): \n' .. vim.inspect(item))
    --   -- -- local zk_util = require('zk.util')
    --   -- -- local path = item.cwd .. '/' .. item.file
    --   -- -- zk_util.fetch_yaml(path)
    --   -- local path = item.cwd .. '/' .. item.file
    --   -- local lines = vim.fn.readfile(path)
    --   -- local yaml = fetch_yaml(lines)
    --   -- -- item.text = string.gsub(item.text, '^(.*):(%d.):(%d.):(.*)$)', yaml.title or item.file)
    --   -- item.text = (yaml.title or item.file) .. ':' .. item.pos[1] .. ':' .. (item.pos[2] + 1) .. ':' .. item.line
    --   -- print('item (After): \n' .. vim.inspect(item))
    --
    --   return item, picker
    -- end,

    display = function(item)
      item.text = item.text .. 'AA'
      print('display: \n' .. vim.inspect(item))
      return item
    end,
  }, opts.snacks_picker or {})

  snacks.picker.grep(grep_opts, cb)
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
