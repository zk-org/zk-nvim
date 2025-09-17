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

-- local zk_state = {
--   loading = false,
--   last_update = 0,
--   update_interval = 1000,
-- }

function M.name_formatter(buf)
  -- TODO: Add checking & keeping, if notebook dir or not
  if config.enabled == true then
    local ok, zk_title = pcall(vim.api.nvim_buf_get_var, buf.bufnr, "zk_title")
    if ok and zk_title then
      return zk_title
    else
      vim.schedule(function()
        M.update_zk_list(function()
          if M.refresh_title(buf) then
            require("bufferline.ui").refresh()
          end
        end)
      end)
    end
    return vim.fn.fnamemodify(buf.name, ":t:r")
  end
end

-- Refresh Buffer Title
function M.refresh_title(buf, callback)
  -- Parse title
  if vim.g.zk_list then
    for _, note in ipairs(vim.g.zk_list) do
      if note.absPath == buf.path then
        local title = config.custom_title(note) -- note.metadata and note.metadata.author or note.title or note.filenameStem or note.id
        vim.api.nvim_buf_set_var(buf.bufnr, "zk_title", title)

        if type(callback) == "function" then
          vim.schedule(callback)
        end
        return true
      end
    end
  end
  return false
end

-- Async update zk_list
function M.update_zk_list(callback)
  require("zk.api").list(nil, {
    select = config.select,
  }, function(err, notes)
    if not err and notes then
      vim.g.zk_list = notes
    else
      print("zk_list update error.")
    end
    if type(callback) == "function" then
      vim.schedule(callback)
    end
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

      -- Update zk_list -> update zk_title -> refresh
      M.update_zk_list(function()
        M.refresh_title(buf, function()
          require("bufferline.ui").refresh()
        end)
      end)
    end,
  })
end

return M
