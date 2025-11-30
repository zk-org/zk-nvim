local util = require("zk.util")

---Set autocmds

---Update zk cache on save and read
vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
  pattern = { "*.md" },
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()
    vim.schedule(function()
      util.zk_buf_cache(bufnr)
    end)
  end,
})

---Fetch zk cache for all buffers on startup
vim.api.nvim_create_autocmd({ "VimEnter" }, {
  callback = function()
    vim.schedule(function()
      util.zk_buf_cache_all()
    end)
  end,
})
