local M = {}

M.defaults = {
  create_user_commands = true,
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
}

M.options = M.defaults

return M
