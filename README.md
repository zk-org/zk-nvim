# zk-nvim
Neovim extension for zk

## Install

Using [packer.nvim](https://github.com/wbthomason/packer.nvim)
```lua
use {
  "mickael-menu/zk-nvim",
  requires = { "neovim/nvim-lspconfig" }
}
```

Using [vim-plug](https://github.com/junegunn/vim-plug)
```viml
Plug "mickael-menu/zk-nvim"
Plug "neovim/nvim-lspconfig"
```

## Setup
```lua
require("zk").setup()
require("telescope").load_extension("zk")
```
This plugin will setup the LSP server for you, there is no need to call `require("lspconfig").zk.setup()`.

The default configuration is as follows
```lua
require("zk").setup({
  lsp = {
    -- automatically attach buffers that match the given filetypes and root_dir
    auto_attach = {
      enabled = true,
      filetypes = { "markdown" },
      -- same as the nvim-lspconfig `root_dir` function
      root_dir = require("lspconfig.util").root_pattern(".zk"),
    },

    -- `config` is passed to `vim.lsp.start_client(config)`
    config = {
      cmd = { "zk", "lsp" },
      name = "zk",
      -- init_options = ...
      -- on_attach = ...
      -- etc, see `:h vim.lsp.start_client()`
    },
  },
})
```

## Commands
```vim
:Telescope zk notes
:Telescope zk tags
:Telescope zk backlinks
```
By default, this plugin will use the path of the currently active buffer to determine the location of the notebook you want to query.
You can override this behavior by providing the path to any file or folder within the notebook you would like to query: `:Telescope zk notes path=/foo/bar` or `require('telescope').extensions.zk.notes({ path = '/foo/bar'})`.

## API

```lua
path = "/path/to/notebook" -- can be nil, falls back to the current buffer then
args = { select = { "title", "absPath", "rawContent" }, sort = { "created" } } -- the `select` key is required, see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zklist
require("zk").list(path, args, function(notes)
  -- do something with the notes
end)
```

```lua
path = "/path/to/notebook" -- can be nil, falls back to the current buffer then
args = { sort = { "note-count" } } -- can be nil, see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zktaglist
require("zk").tag.list(path, args, function(tags)
  -- do something with the tags
end)
```

## Example Mapping
```lua
vim.api.nvim_set_keymap(
  "n",
  "<Leader>fz",
  "<cmd>lua require('telescope').extensions.zk.notes()<CR>",
  { noremap = true }
)
```
