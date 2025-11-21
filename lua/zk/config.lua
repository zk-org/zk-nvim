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
  update = {
    enabled = false,
    triggers = {
      on_save = {
        enabled = false,
        rules = {
          ["modified - %Y-%m-%d %H:%M:%S"] = {
            pattern = "^(modified *: *)(%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d)$",
            format = function(captures, line)
              captures[2] = os.date("%Y-%m-%d %H:%M:%S")
              return table.concat(captures)
            end,
            in_yaml = true,
            dirs = {},
            notebook_paths = {},
          },
        },
      },
    },
  },
}

M.options = M.defaults -- not necessary, but better code completion

return M
