# zk-nvim
Neovim extension for [zk](https://github.com/mickael-menu/zk).

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
> :warning: This plugin will setup and start the LSP server for you, do *not* call `require("lspconfig").zk.setup()`.

#### Default configuration
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
:ZkIndex
:ZkNew [<directory>]
```
or via Lua
```lua
require("zk").cmd.index(path, args) -- path and args are optional
require("zk").cmd.new(path, args) -- path and args are optional
```

### Telescope

```vim
:Telescope zk notes
:Telescope zk tags
:Telescope zk backlinks
```
or via Lua
```lua
require('telescope').extensions.zk.notes()
require('telescope').extensions.zk.tags()
require('telescope').extensions.zk.backlinks()
```
By default, this plugin will use the path of the current buffer to determine the location of your notebook.
You can also explicitly specify a notebook by providing the path to any file or folder within the notebook like so `:Telescope zk notes path=/foo/bar` or so `require('telescope').extensions.zk.notes({ path = '/foo/bar'})`.
Note that if `zk` can't locate your notebook, it will fallback to the value of `$ZK_NOTEBOOK_DIR`.
If you have this environment variable set, it is unlikely you will ever need to explicitly specify the path of a notebook.

## API

The difference between `require("zk").api` (this) and `require("zk").cmd` is that this lets you handle the API results yourself in case you need the extra flexibility.

```lua
-- https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zkindex
-- path and args are optional
require("zk").api.index(path, args, function(stats)
  -- do something with the stats
end)
```

```lua
-- https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zknew
-- path and args are optional
require("zk").api.new(path, args, function(res)
  file_path = res.path
  -- do something with the new file path
end)
```

```lua
-- https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zklist
-- path is optional, args.select is required
-- args = { select = { "title", "absPath", "rawContent" }, sort = { "created" } }
require("zk").api.list(path, args, function(notes)
  -- do something with the notes
end)
```

```lua
-- https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zktaglist
-- path and args are optional
require("zk").api.tag.list(path, args, function(tags)
  -- do something with the tags
end)
```

## Example Mappings
```lua
vim.api.nvim_set_keymap(
  "n",
  "<Leader>zl",
  "<cmd>lua require('telescope').extensions.zk.notes()<CR>",
  { noremap = true }
)

vim.api.nvim_set_keymap(
  "n",
  "<Leader>zb",
  "<cmd>lua require('telescope').extensions.zk.backlinks()<CR>",
  { noremap = true }
)

vim.api.nvim_set_keymap(
  "n",
  "<Leader>zt",
  "<cmd>lua require('telescope').extensions.zk.tags()<CR>",
  { noremap = true }
)
```
