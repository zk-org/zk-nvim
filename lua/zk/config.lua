local M = {}

M.defaults = {
  picker = "select",
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
  mappings = {
    telescope_link_note = { {"i", "n"}, "<C-Y>" }
  }
}

M.options = M.defaults -- not necessary, but better code completion

return M
