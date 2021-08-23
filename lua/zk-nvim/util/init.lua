local M = {}

-- Checks to see if the given text is within a link
M.within_link = function(text)
    local line = vim.fn.getline('.')

    return line:match('%[' .. text .. '.*%|?%]')
end

return M
