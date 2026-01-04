local config = require("zk.config").options.integrations.bufferline

local M = {}

-- Check if bufferline is installed
if config.enabled == true then
  local status, _ = pcall(require, "bufferline")
  if not status then
    vim.notify("bufferline is not installed.", vim.log.levels.ERROR)
    return
  end
end

---Format buffer name (called via bufferline's 'name_formatter' config)
---@param buf table
function M.name_formatter(buf)
  if config.enabled == true then
    if vim.fn.fnamemodify(buf.path, ":e") == "md" then
      local note = vim.b[buf.bufnr].zk
      return note and note.title or vim.fn.fnamemodify(buf.name, ":t:r")
    end
  end
end

---Override name_formatter in bufferline
function M.override_name_formatter()
  if config.enabled and config.override then
    local bufferline_config = require("bufferline.config").get()
    bufferline_config.options.name_formatter = function(buf)
      return M.name_formatter(buf)
    end
    require("bufferline").setup(bufferline_config)
  end
end

return M
