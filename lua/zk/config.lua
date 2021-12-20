local M = {}

M.defaults = {
  lsp = {
    auto_attach = {
      enabled = true,
      filetypes = { "markdown" },
    },
    config = {
      cmd = { "zk", "lsp" },
      name = "zk",
    },
  },
}

M.options = M.defaults

return M
