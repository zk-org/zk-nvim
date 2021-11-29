local utils = {}

utils.debug_tbl = function(tbl, label)
  vim.notify('\n' .. label .. ':\n' .. vim.inspect(tbl), vim.log.levels.TRACE)
end

return utils
