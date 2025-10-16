-- Buffer-local variables:
-- * zk_loading : Prevents duplicate async calls
-- * zk_title   : Cached formatted title

local util = require("zk.util")
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

---Refresh buffer title
---@param buf table
---@param note table?
local function refresh_title(buf, note)
  local title = config.formatter(note)
  if vim.b[buf.bufnr].zk_title ~= title then
    vim.b[buf.bufnr].zk_title = title
    require("bufferline.ui").refresh()
  end
end

---Get zk info (Async)
---@param buf table
---@param callback function?
local function fetch_zk_info(buf, callback)
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
      print(string.format("error in fetch_zk_info: found %s note", #notes))
    end
  end)
end

---Format buffer name (called via bufferline's 'name_formatter' config)
---@param buf table
function M.name_formatter(buf)
  local notebook_root = util.notebook_root(buf.path)
  if notebook_root then
    if config.enabled == true then
      -- Check and apply cached title
      local zk_title = vim.b[buf.bufnr].zk_title
      if zk_title then
        return zk_title
      end
      -- Otherwise, cache the title
      if not vim.b[buf.bufnr].zk_loading then
        vim.b[buf.bufnr].zk_loading = true
        fetch_zk_info(buf, function(buf, note)
          vim.b[buf.bufnr].zk_loading = false
          refresh_title(buf, note)
        end)
      end
    end
    return vim.fn.fnamemodify(buf.name, ":t:r")
  end
end

---Define autocmd
local function define_autocmd()
  if config.enabled == true then
    local augroup = vim.api.nvim_create_augroup("ZkBufferline", { clear = true })
    -- Refresh buffer name
    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = config.pattern,
      group = augroup,
      callback = function(args)
        local buf = { bufnr = args.buf, path = args.file }
        fetch_zk_info(buf, function(note)
          refresh_title(buf, note)
        end)
      end,
    })
  end
end

define_autocmd()

return M
