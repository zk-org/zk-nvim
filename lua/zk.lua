local lsp = require("zk.lsp")
local config = require("zk.config")
local commands = require("zk.commands")

local M = {}

local function setup_lsp_auto_attach()
  --- NOTE: modified version of code in nvim-lspconfig
  local trigger
  local filetypes = config.options.lsp.auto_attach.filetypes
  if filetypes then
    trigger = "FileType " .. table.concat(filetypes, ",")
  else
    trigger = "BufReadPost *"
  end
  vim.api.nvim_command(string.format("autocmd %s lua require'zk'._lsp_buf_auto_add(0)", trigger))
end

---Automatically called via an |autocmd| if lsp.auto_attach is enabled.
--
---@param bufnr number
function M._lsp_buf_auto_add(bufnr)
  if vim.api.nvim_buf_get_option(bufnr, "buftype") == "nofile" then
    return
  end

  if not M.notebook_root(vim.api.nvim_buf_get_name(bufnr)) then
    return
  end

  lsp.buf_add(bufnr)
end

local function setup_commands()
  local function make_command(name, fn_name, range_only)
    return string.format(
      [[command! %s -nargs=? -complete=lua %s lua %s require('zk.commands').%s(assert(loadstring('return ' .. <q-args>))())]],
      range_only and "-range" or "",
      name,
      range_only and [[assert(<range> == 2, "%s must be called with '<,'> range. Try making a selection first.");]]
        or "",
      fn_name
    )
  end

  for key, value in pairs(config.options.commands) do
    commands[key] = value.fn

    if type(value.command) == "string" then
      vim.cmd(make_command(value.command, key))
    elseif type(value.command) == "function" then
      vim.cmd(value.command("require('zk.commands')." .. key))
    elseif type(value.command) == "table" then
      vim.cmd(make_command(value.command.name, key, value.command.range_only))
    end
  end
end

---The entry point of the plugin
--
---@param options? table user configuration options
function M.setup(options)
  config.options = vim.tbl_deep_extend(
    "force",
    config.defaults,
    { commands = require("zk.builtin.commands") },
    options or {}
  )

  if config.options.lsp.auto_attach.enabled then
    setup_lsp_auto_attach()
  end

  setup_commands()
end

return M
