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
  integrations = {
    bufferline = {
      enabled = true,
      pattern = { "*.md" },
      select = { "id", "title", "filenameStem" },
      custom_title = function(note)
        return note.title or note.filenameStem or note.id or nil
      end,
    },
  },
}

M.options = M.defaults -- not necessary, but better code completion

return M
