# zk-nvim
Neovim extension for [zk](https://github.com/mickael-menu/zk).

## Install

Using [packer.nvim](https://github.com/wbthomason/packer.nvim)
```lua
use {
  "mickael-menu/zk-nvim",
  requires = { "neovim/nvim-lspconfig" }
}

-- Telescope is optional
use {
  'nvim-telescope/telescope.nvim',
  requires = { {'nvim-lua/plenary.nvim'} }
}
```

Using [vim-plug](https://github.com/junegunn/vim-plug)
```viml
Plug "mickael-menu/zk-nvim"
Plug "neovim/nvim-lspconfig"

Plug 'nvim-telescope/telescope.nvim' " optional
Plug 'nvim-lua/plenary.nvim' " optional, dependency for Telescope
```

## Setup
```lua
require("zk").setup()
require("telescope").load_extension("zk")
```
> :warning: This plugin will setup and start the LSP server for you, do *not* call `require("lspconfig").zk.setup()`.

**Default configuration**
```lua
require("zk").setup({
  -- create user commands such as :ZkNew
  create_user_commands = true,

  lsp = {
    -- `config` is passed to `vim.lsp.start_client(config)`
    config = {
      cmd = { "zk", "lsp" },
      name = "zk",
      -- init_options = ...
      -- on_attach = ...
      -- etc, see `:h vim.lsp.start_client()`
    },

    -- automatically attach buffers in a zk notebook that match the given filetypes
    auto_attach = {
      enabled = true,
      filetypes = { "markdown" },
    },
  },
})
```

### Notebook Directory Discovery
When you run a notebook command, this plugin will look for a notebook in the following places and order:
1. the current buffer path (i.e. the file you are currently editing),
2. the current working directory,
3. the `$ZK_NOTEBOOK_DIR` environment variable.

We recommend you to export the `$ZK_NOTEBOOK_DIR` environment variable, so that a notebook can always be found.

It is worth noting that for some notebook commands you can explicitly specify a notebook by providing a path to any file or directory within the notebook.
An explicitly provided path will always take precedence and override the automatic notebook discovery.
However, this is always optional, and usually not necessary.

## Commands

### VimL
```vim
" Indexes the notebook
" params
"   (optional) additional options, see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zkindex
:ZkIndex [<options>]

" Creates a new note
" params
"   (optional) additional options, see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zknew
:ZkNew [<options>]

" Creates a new note and uses the last visual selection as the title while replacing the selection with a link to the new note
" params
"   (optional) additional options, see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zknew
:ZkNewLink [<options>]

" Opens a Telescope picker
" params
"   (optional) additional options, see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zklist
:ZkList [<options>]

" Opens a Telescope picker
" params
"   (optional) additional options, see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zktaglist
:ZkTagList [<options>]
```
where `options` can be any valid *Lua* expression that evaluates to a table.

*Examples:*
```vim
:ZkNew { dir = "daily", date = "yesterday" }
:ZkList { createdAfter = "3 days ago", tags = { "work" } }
:'<,'>ZkNewLink " this will use your last visual mode selection. Note that you *must* call this command with the '<,'> range.
```

### Lua
```lua
---Indexes the notebook
--
---@param path? string path to explicitly specify the notebook
---@param options table additional options
---@see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zkindex
require("zk").index(path, options)

---Creates and opens a new note
--
---@param path? string path to explicitly specify the notebook
---@param options table additional options
---@see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zknew
require("zk").new(path, options)

---Creates a new note and uses the last visual selection as the title while replacing the selection with a link to the new note
--
---@param path? string path to explicitly specify the notebook
---@param options table additional options
require("zk").new_link(path, options)

---Opens a Telescope picker
--
---@param path? string path to explicitly specify the notebook
---@param options table additional options
---@see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zklist
require("zk").list(path, options)

---Opens a Telescope picker
--
---@param path? string path to explicitly specify the notebook
---@param options table additional options
---@see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zktaglist
require("zk").tag.list(path, options)
```

*Examples:*
```lua
require("zk").new(nil, { dir = "daily" })
require("zk").list(nil, { createdAfter = "3 days ago", tags = { "work" } })
require("zk").new_link() -- this will use your last visual mode selection
```

As you can see, the `path` is optional, and can usually be omitted; see [Notebook Directory Discovery](#notebook-directory-discovery).

### Telescope
```vim
:Telescope zk notes
:Telescope zk orphans
:Telescope zk backlinks
:Telescope zk links
:Telescope zk related
:Telescope zk tags
```
or via Lua
```lua
require('telescope').extensions.zk.notes()
require('telescope').extensions.zk.orphans()
require('telescope').extensions.zk.backlinks()
require('telescope').extensions.zk.links()
require('telescope').extensions.zk.related()
require('telescope').extensions.zk.tags()
```

The Telescope pickers also allow you to explicitly specify a notebook like so `:Telescope zk notes path=/foo/bar` or so `require('telescope').extensions.zk.notes({ path = '/foo/bar'})`.
However, specifying a `path` is optional, and is usually not necessary; see [Notebook Directory Discovery](#notebook-directory-discovery).

You can even pass the same additional options to the Telescope pickers as described in [list and tag list commands](#commands).

*Example VimL:*
```vim
:Telescope zk notes createdAfter=3\ days\ ago
```

*Example Lua:*
```lua
require('telescope').extensions.zk.notes({ createdAfter = "3 days ago", tags = { "work" } })
```

As you can see, the VimL API is a bit constrained. Whitespace must be escaped and lists and dictionaries are not supported.
It is therefore recommended to use the `:ZkList` and `:ZkTagList` [commands](#commands) instead.

## API

The functions in the API module give you maximum flexibility and provide only a thin Lua friendly layer around zk's API.
You can use it to write your own specialized functions for interacting with zk.

```lua
-- https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zkindex
-- path and options are optional
require("zk").api.index(path, options, function(stats)
  -- do something with the stats
end)
```

```lua
-- https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zknew
-- path and options are optional
require("zk").api.new(path, options, function(res)
  file_path = res.path
  -- do something with the new file path
end)
```

```lua
-- https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zklist
-- path is optional, options.select is required
-- options = { select = { "title", "absPath", "rawContent" }, sort = { "created" } }
require("zk").api.list(path, options, function(notes)
  -- do something with the notes
end)
```

```lua
-- https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zktaglist
-- path and options are optional
require("zk").api.tag.list(path, options, function(tags)
  -- do something with the tags
end)
```

## Example Mappings
```lua

-- Create notes / links

vim.api.nvim_set_keymap(
  "n",
  "<Leader>zc",
  "<cmd>lua require('zk').new()<CR>",
  { noremap = true }
)

vim.api.nvim_set_keymap(
  "x",
  "<Leader>zc",
  "<esc><cmd>lua require('zk').new_link()<CR>",
  { noremap = true }
)

-- Show Telescope pickers

vim.api.nvim_set_keymap(
  "n",
  "<Leader>zn",
  "<cmd>lua require('telescope').extensions.zk.notes()<CR>",
  { noremap = true }
)

vim.api.nvim_set_keymap(
  "n",
  "<Leader>zo",
  "<cmd>lua require('telescope').extensions.zk.orphans()<CR>",
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
  "<Leader>zl",
  "<cmd>lua require('telescope').extensions.zk.links()<CR>",
  { noremap = true }
)

vim.api.nvim_set_keymap(
  "n",
  "<Leader>zt",
  "<cmd>lua require('telescope').extensions.zk.tags()<CR>",
  { noremap = true }
)
```
