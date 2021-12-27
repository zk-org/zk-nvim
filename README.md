# zk-nvim
Neovim extension for [zk](https://github.com/mickael-menu/zk).

> :warning: Due to major refactoring the README is still work in progress and not everything is documented yet.

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
```
> :warning: This plugin will setup and start the LSP server for you, do *not* call `require("lspconfig").zk.setup()`.

**Default configuration**
```lua
require("zk").setup({
  -- can be "telescope", "fzf" or "select" (`vim.ui.select`)
  -- we recommend you to use "telescope" or "fzf"
  picker = "select",

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

  commands = {
    -- ... all the builtin commands, not listed here for brevity
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
:'<,'>ZkNewFromTitleSelection [<options>]

" Creates a new note and uses the last visual selection as the content while replacing the selection with a link to the new note
" params
"   (optional) additional options, see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zknew
:'<,'>ZkNewFromContentSelection [<options>]

" cd into the notebook root
:ZkCd

" Opens a Telescope picker
" params
"   (optional) additional options, see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zklist
:ZkNotes [<options>]

" Opens a Telescope picker
" params
"   (optional) additional options, see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zklist
:ZkBacklinks [<options>]

" Opens a Telescope picker
" params
"   (optional) additional options, see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zklist
:ZkLinks [<options>]

" Opens a Telescope picker, filters for notes that match the text in the last visual selection
" params
"   (optional) additional options, see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zklist
:'<,'>ZkMatch [<options>]

" Opens a Telescope picker
" params
"   (optional) additional options, see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zktaglist
:ZkTags [<options>]
```
where `options` can be any valid *Lua* expression that evaluates to a table.

*Examples:*
```vim
:ZkNew { dir = "daily", date = "yesterday" }
:ZkList { createdAfter = "3 days ago", tags = { "work" } }
:'<,'>ZkNewFromTitleSelection " this will use your last visual mode selection. Note that you *must* call this command with the '<,'> range.
:ZkCd
```

### Lua
```lua
---Indexes the notebook
--
---@param options table additional options
---@param path? string path to explicitly specify the notebook
---@see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zkindex
require("zk.commands").index(options, path)

---Creates and opens a new note
--
---@param options table additional options
---@param path? string path to explicitly specify the notebook
---@see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zknew
require("zk.commands").new(options, path)

---Creates a new note and uses the last visual selection as the title while replacing the selection with a link to the new note
--
---@param options table additional options
---@param path? string path to explicitly specify the notebook
require("zk.commands").new_from_title_selection(options, path)

---Creates a new note and uses the last visual selection as the content while replacing the selection with a link to the new note
--
---@param options table additional options
---@param path? string path to explicitly specify the notebook
require("zk.commands").new_from_content_selection(options, path)


---cd into the notebook root
require("zk.commands").cd(path)

---Opens a Telescope picker
--
---@param options table additional options
---@param path? string path to explicitly specify the notebook
---@see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zklist
require("zk.commands").notes(options, path)

---Opens a Telescope picker
--
---@param options table additional options
---@param path? string path to explicitly specify the notebook
---@see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zklist
require("zk.commands").backlinks(options, path)

---Opens a Telescope picker
--
---@param options table additional options
---@param path? string path to explicitly specify the notebook
---@see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zklist
require("zk.commands").links(options, path)

---Opens a Telescope picker, filters for notes that match the text in the last visual selection
--
---@param options table additional options
---@param path? string path to explicitly specify the notebook
---@see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zklist
require("zk.commands").match(options, path)

---Opens a Telescope picker
--
---@param options table additional options
---@param path? string path to explicitly specify the notebook
---@see https://github.com/mickael-menu/zk/blob/main/docs/editors-integration.md#zktaglist
require("zk.commands").tags(options, path)
```

*Examples:*
```lua
require("zk.commands").new({ dir = "daily" })
require("zk.commands").notes({ createdAfter = "3 days ago", tags = { "work" } })
require("zk.commands").new_from_title_selection() -- this will use your last visual mode selection
```

As you can see, the `path` is optional, and can usually be omitted; see [Notebook Directory Discovery](#notebook-directory-discovery).

### Telescope
It's not really necessary to use this interface, instead we recommend you to use the provided [commands](#commands).

```lua
require("telescope").load_extension("zk")
```

```vim
:Telescope zk notes
:Telescope zk tags
```
or via Lua
```lua
require('telescope').extensions.zk.notes()
require('telescope').extensions.zk.tags()
```

*Example VimL:*
```vim
:Telescope zk notes createdAfter=3\ days\ ago
```

*Example Lua:*
```lua
require('telescope').extensions.zk.notes({ createdAfter = "3 days ago", tags = { "work" } })
```

As you can see, the VimL API is a bit constrained, whitespace must be escaped and lists and dictionaries are not supported.
It is therefore recommended to use the `:ZkNotes` and `:ZkTags` [commands](#commands) instead.

## Custom Commands

> :warning: This documentation is not complete. More details coming soon.

*Example:*

We add a custom "Orphans" command which will list all notes that are orphans, i.e. not referenced by any other note.
The following code in the `setup` function will create
1. a vim user command, and
2. a Lua function
for our custom "Orphans" command.
As the builtin commands do, the vim user command the was created for us also accepts a Lua table as its argument.
We can then call it like so `:ZkOrphans { tags = "work" }` for example.

```lua
local api = require("zk.api")
local pickers = require("zk.pickers")

require("zk").setup({
  commands = {
    orphans = { -- will make `fn` available as `require("zk.commands").orphans(options, path)`
      command = "ZkOrphans", -- will create a `:ZkOrphans [<options>]` command for you
      fn = function(options, path)
        options = pickers.make_note_picker_api_options({ orphan = true }, options)
        api.list(path, options, function(notes)
          pickers.note_picker(notes, "Zk Orphans") -- will open the users picker (telescope/fzf/select)
        end)
      end,
    },
  }
})
```

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

<!-- ## Example Mappings -->
<!-- ```lua -->
<!---->
<!-- -- Create notes / links -->
<!---->
<!-- vim.api.nvim_set_keymap( -->
<!--   "n", -->
<!--   "<Leader>zc", -->
<!--   "<cmd>lua require('zk').new()<CR>", -->
<!--   { noremap = true } -->
<!-- ) -->
<!---->
<!-- vim.api.nvim_set_keymap( -->
<!--   "x", -->
<!--   "<Leader>zc", -->
<!--   "<esc><cmd>lua require('zk').new_link()<CR>", -->
<!--   { noremap = true } -->
<!-- ) -->
<!---->
<!-- -- Show Telescope pickers -->
<!---->
<!-- vim.api.nvim_set_keymap( -->
<!--   "n", -->
<!--   "<Leader>zn", -->
<!--   "<cmd>lua require('telescope').extensions.zk.notes()<CR>", -->
<!--   { noremap = true } -->
<!-- ) -->
<!---->
<!-- vim.api.nvim_set_keymap( -->
<!--   "n", -->
<!--   "<Leader>zo", -->
<!--   "<cmd>lua require('telescope').extensions.zk.orphans()<CR>", -->
<!--   { noremap = true } -->
<!-- ) -->
<!---->
<!-- vim.api.nvim_set_keymap( -->
<!--   "n", -->
<!--   "<Leader>zb", -->
<!--   "<cmd>lua require('telescope').extensions.zk.backlinks()<CR>", -->
<!--   { noremap = true } -->
<!-- ) -->
<!---->
<!-- vim.api.nvim_set_keymap( -->
<!--   "n", -->
<!--   "<Leader>zl", -->
<!--   "<cmd>lua require('telescope').extensions.zk.links()<CR>", -->
<!--   { noremap = true } -->
<!-- ) -->
<!---->
<!-- vim.api.nvim_set_keymap( -->
<!--   "n", -->
<!--   "<Leader>zt", -->
<!--   "<cmd>lua require('telescope').extensions.zk.tags()<CR>", -->
<!--   { noremap = true } -->
<!-- ) -->
<!-- ``` -->
