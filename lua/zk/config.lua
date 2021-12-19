local M = {}

M.defaults = {
  lsp = {
    auto_attach = {
      enabled = true,
      filetypes = { "markdown" },
      root_dir = require("lspconfig.util").root_pattern(".zk"),
    },
    config = {
      cmd = { "zk", "lsp" },
      name = "zk",
    },
  },
}

M.options = M.defaults

return M
