local M = {}

M.defaults = {
  picker = "select",
  lsp = {
    config = {
      cmd = { "zk", "lsp" },
      name = "zk",
      filetypes = { "markdown" },
      root_markers = { ".zk" },
    },
    auto_attach = {
      enabled = true, -- calls vim.lsp.enable()
    },
  },
}

M.options = M.defaults -- not necessary, but better code completion

return M
