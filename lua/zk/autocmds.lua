local util = require("zk.util")

---Set autocmds

---Add zk_buf_cache() on save
vim.api.nvim_create_autocmd({ "BufWritePost", "BufWinEnter" }, {
  pattern = { "*.md" },
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()
    vim.schedule(function()
      util.zk_buf_cache(bufnr)
    end)
  end,
})

---Add zk_buf_cache_all() on nvim start
vim.api.nvim_create_autocmd({ "VimEnter" }, {
  callback = function()
    vim.schedule(function()
      util.zk_buf_cache_all()
    end)
  end,
})
