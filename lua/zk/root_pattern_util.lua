-- NOTE: everything in this module is copied from nvim-lspconfig (https://github.com/neovim/nvim-lspconfig)
-- NOTE: we need this util until the code from lspconfig is merged into core

local vim = vim
local uv = vim.loop

local function has_new_vim_validate()
  return pcall(vim.validate, 'test', 'foo', 'string')
end
local function validate(args)
  if has_new_vim_validate() then
    for name, def in pairs(args) do
      local value, validator, msg = def[1], def[2], def[3]
      vim.validate(name, value, validator, msg)
    end
  else
    vim.validate(args)
  end
end

local M = {}

-- Some path utilities

local function tbl_flatten(...)
  if vim.fn.has("nvim-0.10") == 1 then
    return vim.iter({ ... }):flatten():totable()
  else
    return vim.tbl_flatten({ ... })
  end
end

M.path = (function()
  local is_windows = uv.os_uname().version:match("Windows")

  local function escape_wildcards(path)
    return path:gsub("([%[%]%?%*])", "\\%1")
  end

  local function exists(filename)
    local stat = uv.fs_stat(filename)
    return stat and stat.type or false
  end

  local function is_fs_root(path)
    if is_windows then
      return path:match("^%a:$")
    else
      return path == "/"
    end
  end

  local function dirname(path)
    local strip_dir_pat = "/([^/]+)$"
    local strip_sep_pat = "/$"
    if not path or #path == 0 then
      return
    end
    local result = path:gsub(strip_sep_pat, ""):gsub(strip_dir_pat, "")
    if #result == 0 then
      if is_windows then
        return path:sub(1, 2):upper()
      else
        return "/"
      end
    end
    return result
  end

  local function path_join(...)
    return table.concat(tbl_flatten({ ... }), "/")
  end

  -- Iterate the path until we find the rootdir.
  local function iterate_parents(path)
    local function it(_, v)
      if v and not is_fs_root(v) then
        v = dirname(v)
      else
        return
      end
      if v and uv.fs_realpath(v) then
        return v, path
      else
        return
      end
    end
    return it, path, path
  end

  return {
    escape_wildcards = escape_wildcards,
    exists = exists,
    join = path_join,
    iterate_parents = iterate_parents,
  }
end)()

function M.search_ancestors(startpath, func)
  validate({ func = { func, "f" } })
  if func(startpath) then
    return startpath
  end
  local guard = 100
  for path in M.path.iterate_parents(startpath) do
    -- Prevent infinite recursion if our algorithm breaks
    guard = guard - 1
    if guard == 0 then
      return
    end

    if func(path) then
      return path
    end
  end
end

function M.root_pattern(...)
  local patterns = tbl_flatten({ ... })
  local function matcher(path)
    for _, pattern in ipairs(patterns) do
      for _, p in ipairs(vim.fn.glob(M.path.join(M.path.escape_wildcards(path), pattern), true, true)) do
        if M.path.exists(p) then
          return path
        end
      end
    end
  end
  return function(startpath)
    return M.search_ancestors(startpath, matcher)
  end
end

return M
