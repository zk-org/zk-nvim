local commands = {}

local key_fn_map = {}
local key_user_command_map = {}

local function add_user_command(user_command, fn, fn_name, range_only)
  if vim.api.nvim_add_user_command then
    vim.api.nvim_add_user_command(user_command, function(params)
      if range_only then
        assert(params.range == 2, "Must be called with '<,'> range. Try making a selection first.")
      end
      fn(loadstring("return " .. params.args)())
    end, { nargs = "?", force = true, range = range_only, complete = "lua" })
  else
    -- for compatibility. remove this sometime in the future when neovim 0.7.0 is released
    vim.cmd(table.concat({
      "command!",
      range_only and "-range" or "",
      "-nargs=?",
      "-complete=lua",
      user_command,
      "lua",
      range_only and [[assert(<range> == 2, "Must be called with '<,'> range. Try making a selection first.");]],
      "require('zk.commands')." .. fn_name .. "(loadstring('return ' .. <q-args>)())",
    }, " "))
  end
end

local function del_user_command(user_command)
  if vim.api.nvim_add_user_command then
    vim.api.nvim_del_user_command(user_command)
  else
    vim.cmd("delcommand " .. user_command)
  end
end

return setmetatable(commands, {
  __index = function(_, key)
    return key_fn_map[key]
  end,
  __newindex = function(_, key, value)
    if type(value) == "table" then
      local user_command
      if type(value.command) == "string" then
        user_command = value.command
        add_user_command(user_command, value.fn, key)
      elseif type(value.command) == "table" then
        user_command = value.command[1]
        add_user_command(user_command, value.fn, key, value.command.range_only)
      end
      value = value.fn
      key_user_command_map[key] = user_command
    else
      local user_command = key_user_command_map[key]
      if user_command then
        del_user_command(user_command)
      end
    end
    key_fn_map[key] = value
  end,
})
