local M = {}

local name_fn_map = {}

---A thin wrapper around `vim.api.nvim_create_user_command` which parses
---the `params.args` of the command as a Lua table and passes it on to `fn`,
---along with `params.range`, but only for commands that opted in via
---{needs_selection} or {optional_selection}.
---@param name string
---@param fn function
---@param opts? table {needs_selection} makes sure the command is called with a range.
---{optional_selection} allows (but doesn't require) the command to be called with a range.
---@see vim.api.nvim_create_user_command
function M.add(name, fn, opts)
  opts = opts or {}
  local accepts_range = opts.needs_selection or opts.optional_selection
  vim.api.nvim_create_user_command(name, function(params) -- vim.api.nvim_add_user_command
    if opts.needs_selection then
      assert(
        params.range == 2,
        "Command needs a selection and must be called with '<,'> range. Try making a selection first."
      )
    end
    local options = loadstring("return " .. params.args)()
    if accepts_range then
      fn(options, params.range)
    else
      fn(options)
    end
  end, {
    nargs = "?",
    force = true,
    range = accepts_range,
    complete = "lua",
  })
  name_fn_map[name] = fn
end

function M.get(name)
  return name_fn_map[name]
end

---Wrapper around `vim.api.nvim_del_user_command`
---@param name string
---@see vim.api.nvim_del_user_command
function M.del(name)
  name_fn_map[name] = nil
  vim.api.nvim_del_user_command(name)
end

return M
