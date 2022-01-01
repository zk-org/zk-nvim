local M = {}

local name_fn_map = {}

-- NOTE: remove this once `vim.api.nvim_add_user_command` is officially released
M._name_command_map = {}

-- NOTE: remove this helper once `vim.api.nvim_add_user_command` is officially released
local function nvim_add_user_command(name, command, opts)
  if vim.api.nvim_add_user_command then
    vim.api.nvim_add_user_command(name, command, opts)
  else
    assert(type(command) == "function", "Not supported in this version of Neovim.")
    M._name_command_map[name] = command
    vim.cmd(table.concat({
      "command" .. (opts.force and "!" or ""),
      opts.range and "-range" or "",
      opts.nargs and ("-nargs=" .. opts.nargs) or "",
      opts.complete and ("-complete=" .. opts.complete) or "",
      name,
      string.format("lua require('zk.commands')._name_command_map['%s']({ args = <q-args>, range = <range> })", name),
    }, " "))
  end
end

-- NOTE: remove this helper once `vim.api.nvim_del_user_command` is officially released
local function nvim_del_user_command(name)
  if vim.api.nvim_add_user_command then
    vim.api.nvim_del_user_command(name)
  else
    M._name_command_map[name] = nil
    vim.cmd("delcommand " .. name)
  end
end

---A thin wrapper around `vim.api.nvim_add_user_command` which parses the `params.args` of the command as a Lua table and passes it on to `fn`.
---@param name string
---@param fn function
---@param opts? table {needs_selection} makes sure the command is called with a range
---@see vim.api.nvim_add_user_command
function M.add(name, fn, opts)
  opts = opts or {}
  nvim_add_user_command(name, function(params) -- vim.api.nvim_add_user_command
    if opts.needs_selection then
      assert(
        params.range == 2,
        "Command needs a selection and must be called with '<,'> range. Try making a selection first."
      )
    end
    fn(loadstring("return " .. params.args)())
  end, { nargs = "?", force = true, range = opts.needs_selection, complete = "lua" })
  name_fn_map[name] = fn
end

function M.get(name)
  return name_fn_map[name]
end

---Wrapper around `vim.api.nvim_del_user_command`
---@param name string
---@see vim.api.nvim_add_user_command
function M.del(name)
  name_fn_map[name] = nil
  nvim_del_user_command(name) -- vim.api.nvim_del_user_command
end

return M
