local config = require("zk.config").options.integrations.bufferline

local M = {}

if config.enabled == true then
  local status, _ = pcall(require, "bufferline")
  if not status then
    vim.notify("bufferline is not installed.", vim.log.levels.ERROR)
    return
  end
end

-- Add mandatory fields
config.select = vim.tbl_extend("force", { "id", "absPath", "title", "filenameStem" }, config.select)

---@param buf table
function M.name_formatter(buf)
  -- TODO: Add checking & keeping, if notebook dir or not
  if config.enabled == true then
    local ok, zk_title = pcall(vim.api.nvim_buf_get_var, buf.bufnr, "zk_title")
    if ok and zk_title then
      return zk_title
    else
      vim.schedule(function()
        M.get_zk_info(buf, function()
          M.refresh_title(buf)
        end)
      end)
    end
    return vim.fn.fnamemodify(buf.name, ":t:r")
  end
end

-- Refresh Buffer Title
---@param buf table
---@param note table?
function M.refresh_title(buf, note)
  if note then
    -- Parse title
    local title = config.custom_title(note)
    vim.api.nvim_buf_set_var(buf.bufnr, "zk_title", title)
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
      -- vim.g.zk_list = notes
      local title = config.custom_title(notes[1])
      vim.api.nvim_buf_set_var(buf.bufnr, "zk_title", title)
      if type(callback) == "function" then
        callback(buf, notes[1])
      end
      return true
    else
      print(string.format("error in get_zk_info: found %s note", #notes))
    end
    -- if type(callback) == "function" then
    --   vim.schedule(callback)
    -- end
  end)
end

if config.enabled == true then
  -- Add autocmd BufWritePost
  vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = config.pattern,
    callback = function(args)
      local bufnr = args.buf
      local path = args.file
      local buf = { bufnr = bufnr, path = path }

      -- local buftype = vim.bo[bufnr].buftype
      -- if buftype ~= "" then
      --   return
      -- end

      -- Clear existing zk_title
      vim.b[bufnr].zk_title = nil

      -- Get zk info (Async) -> Update vim.b.zk_title -> Refresh bufferline
      M.get_zk_info(buf, function(note)
        M.refresh_title(buf, note)
      end)
    end,
  })
end

return M
