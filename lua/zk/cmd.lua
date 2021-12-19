local api = require("zk.api")

local M = {}

function M.index(path, args)
  api.index(path, args, function(stats)
    vim.notify(vim.inspect(stats))
  end)
end

function M.new(path, args)
  api.new(path, args, function(res)
    vim.cmd("edit " .. res.path)
  end)
end

return M
