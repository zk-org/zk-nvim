local M = {}

M.defaults = {
  lsp = {
    config = {
      cmd = { "zk", "lsp" },
      name = "zk",
    },
    auto_attach = {
      enabled = true,
      filetypes = { "markdown" },
    },
  },
  picker = "telescope",
}

M.options = M.defaults -- not necessary, but better code completion

return M
