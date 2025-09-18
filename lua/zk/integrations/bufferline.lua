local util = require("zk.util")
local config = require("zk.config").options.integrations.bufferline

local M = {}

if config.enabled == true then
  local status, _ = pcall(require, "bufferline")
  if not status then
    vim.notify("bufferline is not installed.", vim.log.levels.ERROR)
    return
  end
end

---@param buf table
function M.zk_name_formatter(buf)
  local notebook_root = util.notebook_root(buf.path)
  if notebook_root then
    if config.enabled == true then
      local zk_title = vim.b[buf.bufnr].zk_title
      if zk_title then
        return zk_title
      end
      M.get_zk_info(buf, function(buf, note)
        M.refresh_title(buf, note)
      end)
    end
    return vim.fn.fnamemodify(buf.name, ":t:r")
  end
end

-- Refresh Buffer Title
---@param buf table
---@param note table?
function M.refresh_title(buf, note)
  local title = config.formatter(note)
  if vim.b[buf.bufnr].zk_title ~= title then
    vim.b[buf.bufnr].zk_title = title
    require("bufferline.ui").refresh()
  end
end

-- Get zk info (Async)
---@param buf table
---@param callback function?
function M.get_zk_info(buf, callback)
  require("zk.api").list(nil, {
    select = config.select,
    hrefs = { buf.path },
    limit = 1,
  }, function(err, notes)
    if not err and notes and (#notes == 1) then
      if type(callback) == "function" then
        callback(buf, notes[1])
      end
    else
      print(string.format("error in get_zk_info: found %s note", #notes))
    end
  end)
end

-- Add autocmd
if config.enabled == true then
  vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = config.pattern,
    callback = function(args)
      local bufnr = args.buf
      local path = args.file
      local buf = { bufnr = bufnr, path = path }
      M.get_zk_info(buf, function(note)
        M.refresh_title(buf, note)
      end)
    end,
  })
end

return M
