local M = {}

M.defaults = {
  picker = "select",
  lsp = {
    config = {
      cmd = { "zk", "lsp" },
      name = "zk",
      filetypes = { "markdown" },
      root_dir = vim.fs.root(0, { ".zk" }),
    },
    auto_attach = {
      enabled = true,
    },
  },
}

M.options = M.defaults -- not necessary, but better code completion

return M
