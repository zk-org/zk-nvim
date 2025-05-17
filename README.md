# zk-nvim

Neovim extension for the [`zk`](https://github.com/zk-org/zk) plain text
note-taking assistant.

Checkout [Shivan's](https://github.com/shivan-s) video,
[_Note-taking System ALL Programmers Should Consider_](https://www.youtube.com/watch?v=UzhZb7e4l4Y),
to see it in action.

## Requirements

| `zk-nvim`     | `zk`            | Neovim         |
| ------------- | --------------- | -------------- |
| 0.4.0 - HEAD  | >=0.15.1        | >= 0.11.0      |
| 0.2.0 - 0.3.0 | 0.14.1 - 0.15.1 | 0.9.5 - 0.10.4 |
| 0.1.1         | 0.13.0 - 0.14.1 | 0.9.5          |
| 0.1.0         | 0.13.0 - 0.14.1 | 0.8.0 - 0.9.5  |

## Installation

Via [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use("zk-org/zk-nvim")
```

Via [vim-plug](https://github.com/junegunn/vim-plug)

```viml
Plug 'zk-org/zk-nvim'
```

Via [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "zk-org/zk-nvim",
  config = function()
    require("zk").setup({
      -- See Setup section below
    })
  end
}
```

To get the best experience, it's recommended to also install either
[Telescope](https://github.com/nvim-telescope/telescope.nvim),
[fzf](https://github.com/junegunn/fzf),
[mini.pick](https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-pick.md),
or
[snacks.picker](https://github.com/folke/snacks.nvim/blob/main/docs/picker.md)

## Setup

> [!IMPORTANT] 
> If you have the [zk cli](https://github.com/zk-org/zk) installed,
> then you _do not need to install `zk lsp`_ via Mason (or otherwise). 

Default `lazy.nvim` setup:

```lua
return {
  "zk-org/zk-nvim",
  config = function()
    vim.lsp.enable("zk") -- for neovim 0.11.*
    require("zk").setup({
      -- Can be "telescope", "fzf", "fzf_lua", "minipick", "snacks_picker",
      -- or select" (`vim.ui.select`).
      picker = "select",

      lsp = {
        -- `config` is passed to `vim.lsp.start(config)`
        config = {
          cmd = { "zk", "lsp" },
          name = "zk",
          -- on_attach = ...
          -- etc, see `:h vim.lsp.start()`
        },

        -- automatically attach buffers in a zk notebook that match the given filetypes
        auto_attach = {
          enabled = true,
          filetypes = { "markdown" },
        },
      },
    })
  end,
}
```

Note that the `setup` function will not add any key mappings for you. If you
want to add key mappings, see the [example mappings](#example-mappings).

### Picker Options

You can define default configurations for the pickers opened by `zk-nvim`,
allowing you to apply a specific theme or layout for `zk-nvim`. This works for
all supported pickers, but you'll need to refer to the relevant configuration
options for each picker.

```lua
require("zk").setup({
    picker_options = {
        telescope = require("telescope.themes").get_ivy(),

        -- or if you use snacks picker

        snacks_picker = {
            layout = {
                preset = "ivy",
            }
        },
    },
    ...
})
```

### Notebook Directory Discovery

When you run a notebook command, this plugin will look for a notebook in the
following places and order:

1. the current buffer path (i.e. the file you are currently editing),
2. the current working directory,
3. the `$ZK_NOTEBOOK_DIR` environment variable.

We recommend you to export the `$ZK_NOTEBOOK_DIR` environment variable, so that
a notebook can always be found.

It is worth noting that for some notebook commands you can explicitly specify a
notebook by providing a path to any file or directory within the notebook. An
explicitly provided path will always take precedence and override the automatic
notebook discovery. However, this is always optional, and usually not necessary.

## Getting Started

After you have installed the plugin and added the setup code to your config, you
are good to go. If you are not familiar with `zk`, we recommend you to also read
the [`zk` docs](https://github.com/zk-org/zk/tree/main/docs).

When using the default config, the `zk` LSP client will automatically attach
itself to buffers inside your notebook and provide capabilities like completion,
hover and go-to-definition; see https://github.com/zk-org/zk/issues/22 for a
full list of what is supported.

Try out different [commands](#built-in-commands) such as `:ZkNotes` or `:ZkNew`,
see what they can do, and learn as you go.

## Built-in Commands

```vim
" Indexes the notebook
" params
"   (optional) additional options, see https://github.com/zk-org/zk/blob/main/docs/tips/editors-integration.md#zkindex
:ZkIndex [{options}]

" Creates and edits a new note
"
" Use the `inline = true` option to insert the content of the created note at the caret position, instead of writing the note on the file system.
"
" params
"   (optional) additional options, see https://github.com/zk-org/zk/blob/main/docs/tips/editors-integration.md#zknew
:ZkNew [{options}]

" Creates a new note and uses the last visual selection as the title while replacing the selection with a link to the new note
"
" Use the `inline = true` option to replace the selection with the content of the created note, instead of writing the note on the file system.
"
" params
"   (optional) additional options, see https://github.com/zk-org/zk/blob/main/docs/tips/editors-integration.md#zknew
:'<,'>ZkNewFromTitleSelection [{options}]

" Creates a new note and uses the last visual selection as the content while replacing the selection with a link to the new note
"
" Use the `inline = true` option to replace the selection with the content of the created note, instead of writing the note on the file system.
"
" params
"   (optional) additional options, see https://github.com/zk-org/zk/blob/main/docs/tips/editors-integration.md#zknew
:'<,'>ZkNewFromContentSelection [{options}]

" cd into the notebook root
" params
"   (optional) additional options
:ZkCd [{options}]

" Opens a notes picker
" params
"   (optional) additional options, see https://github.com/zk-org/zk/blob/main/docs/tips/editors-integration.md#zklist
:ZkNotes [{options}]

" Opens a notes picker for active buffers (showing notebook files only).
" params
"   (optional) additional options, see https://github.com/zk-org/zk/blob/main/docs/tips/editors-integration.md#zklist
:ZkBuffers [{options}]

" Opens a notes picker for the backlinks of the current buffer
" params
"   (optional) additional options, see https://github.com/zk-org/zk/blob/main/docs/tips/editors-integration.md#zklist
:ZkBacklinks [{options}]

" Opens a notes picker for the outbound links of the current buffer
" params
"   (optional) additional options, see https://github.com/zk-org/zk/blob/main/docs/tips/editors-integration.md#zklist
:ZkLinks [{options}]

" Inserts a link at the cursor location or around the selected text.
" params
"   (optional) additional options, see https://github.com/zk-org/zk/blob/main/docs/tips/editors-integration.md#zklist
"   One additional option is `matchSelected` (boolean) which is only applicable to inserting a link around selected text. If `true`, the note picker will search for notes similar to the selected text. Otherwise, the note picker will load all notes to filter through.
"    e.g. :'<'>ZkInsertLinkAtSelection {matchSelected = true}
:ZkInsertLink
:'<,'>ZkInsertLinkAtSelection [{options}]

" Opens a notes picker, filters for notes that match the text in the last visual selection
" params
"   (optional) additional options, see https://github.com/zk-org/zk/blob/main/docs/tips/editors-integration.md#zklist
:'<,'>ZkMatch [{options}]

" Opens a notes picker, filters for notes with the selected tags
" params
"   (optional) additional options, see https://github.com/zk-org/zk/blob/main/docs/tips/editors-integration.md#zktaglist
:ZkTags [{options}]
```

The `options` parameter can be any valid _Lua_ expression that evaluates to a
table. For a list of available options, refer to the
[`zk` docs](https://github.com/zk-org/zk/blob/main/docs/tips/editors-integration.md#custom-commands).
In addition, `options.notebook_path` can be used to explicitly specify a
notebook by providing a path to any file or directory within the notebook; see
[Notebook Directory Discovery](#notebook-directory-discovery).

_Examples:_

```vim
:ZkNew { dir = "daily", date = "yesterday" }
:ZkNotes { createdAfter = "3 days ago", tags = { "work" } }
:'<,'>ZkNewFromTitleSelection " this will use your last visual mode selection. Note that you *must* call this command with the '<,'> range.
:ZkCd
```

---

**Via Lua**

You can access the underlying Lua function of a command, with
`require("zk.commands").get`.

_Examples:_

```lua
require("zk.commands").get("ZkNew")({ dir = "daily" })
require("zk.commands").get("ZkNotes")({ createdAfter = "3 days ago", tags = { "work" } })
require("zk.commands").get("ZkNewFromTitleSelection")()
```

## Custom Commands

```lua
---A thin wrapper around `vim.api.nvim_add_user_command` which parses the `params.args` of the command as a Lua table and passes it on to `fn`.
---@param name string
---@param fn function
---@param opts? table {needs_selection} makes sure the command is called with a range
---@see vim.api.nvim_add_user_command
require("zk.commands").add(name, fn, opts)
```

_Example 1:_

Let us add a custom `:ZkOrphans` command that will list all notes that are
orphans, i.e. not referenced by any other note.

```lua
local zk = require("zk")
local commands = require("zk.commands")

commands.add("ZkOrphans", function(options)
  options = vim.tbl_extend("force", { orphan = true }, options or {})
  zk.edit(options, { title = "Zk Orphans" })
end)
```

This adds the `:ZkOrphans [{options}]` vim user command, which accepts an
`options` Lua table as an argument. We can execute it like this
`:ZkOrphans { tags = { "work" } }` for example.

> Note: The `zk.edit` function is from the [high-level API](#high-level-api),
> which also contains other functions that might be useful for your custom
> commands.

_Example 2:_

Chances are that this will not be our only custom command following this
pattern. So let's also add a `:ZkRecents` command and make the pattern a bit
more reusable.

```lua
local zk = require("zk")
local commands = require("zk.commands")

local function make_edit_fn(defaults, picker_options)
  return function(options)
    options = vim.tbl_extend("force", defaults, options or {})
    zk.edit(options, picker_options)
  end
end

commands.add("ZkOrphans", make_edit_fn({ orphan = true }, { title = "Zk Orphans" }))
commands.add("ZkRecents", make_edit_fn({ createdAfter = "2 weeks ago" }, { title = "Zk Recents" }))
```

## High-level API

The high-level API is inspired by the commands provided by the `zk` CLI tool;
see `zk --help`. It's mainly used for the implementation of built-in and custom
commands.

```lua
---Cd into the notebook root
--
---@param options? table
require("zk").cd(options)
```

```lua
---Creates and edits a new note
--
---@param options? table additional options
---@see https://github.com/zk-org/zk/blob/main/docs/tips/editors-integration.md#zknew
require("zk").new(options)
```

```lua
---Indexes the notebook
--
---@param options? table additional options
---@see https://github.com/zk-org/zk/blob/main/docs/tips/editors-integration.md#zkindex
require("zk").index(options)
```

```lua
---Opens a notes picker, and calls the callback with the selection
--
---@param options? table additional options
---@param picker_options? table options for the picker
---@param cb function
---@see https://github.com/zk-org/zk/blob/main/docs/tips/editors-integration.md#zklist
---@see zk.ui.pick_notes
require("zk").pick_notes(options, picker_options, cb)
```

```lua
---Opens a tags picker, and calls the callback with the selection
--
---@param options? table additional options
---@param picker_options? table options for the picker
---@param cb function
---@see https://github.com/zk-org/zk/blob/main/docs/tips/editors-integration.md#zktaglist
---@see zk.ui.pick_tags
require("zk").pick_tags(options, picker_options, cb)
```

```lua
---Opens a notes picker, and edits the selected notes
--
---@param options? table additional options
---@param picker_options? table options for the picker
---@see https://github.com/zk-org/zk/blob/main/docs/tips/editors-integration.md#zklist
---@see zk.ui.pick_notes
require("zk").edit(options, picker_options)
```

## API

The functions in the API module give you maximum flexibility and provide only a
thin Lua friendly layer around `zk`'s LSP API. You can use it to write your own
specialized functions for interacting with `zk`.

```lua
---@param path? string path to explicitly specify the notebook
---@param options? table additional options
---@param cb function callback function
---@see https://github.com/zk-org/zk/blob/main/docs/tips/editors-integration.md#zkindex
require("zk.api").index(path, options, function(err, stats)
  -- do something with the stats
end)
```

```lua
---@param path? string path to explicitly specify the notebook
---@param options? table additional options
---@param cb function callback function
---@see https://github.com/zk-org/zk/blob/main/docs/tips/editors-integration.md#zknew
require("zk.api").new(path, options, function(err, res)
  file_path = res.path
  -- do something with the new file path
end)
```

```lua
---@param path? string path to explicitly specify the notebook
---@param options table additional options
---@param cb function callback function
---@see https://github.com/zk-org/zk/blob/main/docs/tips/editors-integration.md#zklist
require("zk.api").list(path, options, function(err, notes)
  -- do something with the notes
end)
```

```lua
---@param path? string path to explicitly specify the notebook
---@param options? table additional options
---@param cb function callback function
---@see https://github.com/zk-org/zk/blob/main/docs/tips/editors-integration.md#zktaglist
require("zk.api").tag.list(path, options, function(err, tags)
  -- do something with the tags
end)
```

## Pickers

Used by the [high-level API](#high-level-api) to display the results of the
[API](#api).

```lua
---Opens a notes picker
--
---@param notes list
---@param options? table containing {picker}, {title}, {multi_select} keys
---@param cb function
require("zk.ui").pick_notes(notes, options, cb)
```

```lua
---Opens a tags picker
--
---@param tags list
---@param options? table containing {picker}, {title}, {multi_select} keys
---@param cb function
require("zk.ui").pick_tags(tags, options, cb)
```

```lua
---To be used in zk.api.list as the `selection` in the additional options table
--
---@param options table the same options that are use for pick_notes
---@return table api selection
require("zk.ui").get_pick_notes_list_api_selection(options)
```

## Example Mappings

Add these global mappings in your main Neovim config:

```lua
local opts = { noremap=true, silent=false }

-- Create a new note after asking for its title.
vim.api.nvim_set_keymap("n", "<leader>zn", "<Cmd>ZkNew { title = vim.fn.input('Title: ') }<CR>", opts)

-- Open notes.
vim.api.nvim_set_keymap("n", "<leader>zo", "<Cmd>ZkNotes { sort = { 'modified' } }<CR>", opts)
-- Open notes associated with the selected tags.
vim.api.nvim_set_keymap("n", "<leader>zt", "<Cmd>ZkTags<CR>", opts)

-- Search for the notes matching a given query.
vim.api.nvim_set_keymap("n", "<leader>zf", "<Cmd>ZkNotes { sort = { 'modified' }, match = { vim.fn.input('Search: ') } }<CR>", opts)
-- Search for the notes matching the current visual selection.
vim.api.nvim_set_keymap("v", "<leader>zf", ":'<,'>ZkMatch<CR>", opts)
```

You can add additional key mappings for Markdown buffers located in a `zk`
notebook, using `ftplugin`. First, make sure it is enabled in your Neovim
config:

```viml
filetype plugin on
```

Then, create a new file under `~/.config/nvim/ftplugin/markdown.lua` to setup
the mappings:

```lua
-- Add the key mappings only for Markdown files in a zk notebook.
if require("zk.util").notebook_root(vim.fn.expand('%:p')) ~= nil then
  local function map(...) vim.api.nvim_buf_set_keymap(0, ...) end
  local opts = { noremap=true, silent=false }

  -- Open the link under the caret.
  map("n", "<CR>", "<Cmd>lua vim.lsp.buf.definition()<CR>", opts)

  -- Create a new note after asking for its title.
  -- This overrides the global `<leader>zn` mapping to create the note in the same directory as the current buffer.
  map("n", "<leader>zn", "<Cmd>ZkNew { dir = vim.fn.expand('%:p:h'), title = vim.fn.input('Title: ') }<CR>", opts)
  -- Create a new note in the same directory as the current buffer, using the current selection for title.
  map("v", "<leader>znt", ":'<,'>ZkNewFromTitleSelection { dir = vim.fn.expand('%:p:h') }<CR>", opts)
  -- Create a new note in the same directory as the current buffer, using the current selection for note content and asking for its title.
  map("v", "<leader>znc", ":'<,'>ZkNewFromContentSelection { dir = vim.fn.expand('%:p:h'), title = vim.fn.input('Title: ') }<CR>", opts)

  -- Open notes linking to the current buffer.
  map("n", "<leader>zb", "<Cmd>ZkBacklinks<CR>", opts)
  -- Alternative for backlinks using pure LSP and showing the source context.
  --map('n', '<leader>zb', '<Cmd>lua vim.lsp.buf.references()<CR>', opts)
  -- Open notes linked by the current buffer.
  map("n", "<leader>zl", "<Cmd>ZkLinks<CR>", opts)

  -- Preview a linked note.
  map("n", "K", "<Cmd>lua vim.lsp.buf.hover()<CR>", opts)
  -- Open the code actions for a visual selection.
  map("v", "<leader>za", ":'<,'>lua vim.lsp.buf.range_code_action()<CR>", opts)
end
```

# Miscellaneous

## Syntax Highlighting Tips

You can extend Neovim's built-in Markdown syntax with proper highlighting and
conceal support for `[[Wikilinks]]`, and conceal support for standard
`[Markdown Links]()`. Create a new file under
`~/.config/nvim/after/syntax/markdown.vim` for this purpose:

```vim
" markdownWikiLink is a new region
syn region markdownWikiLink matchgroup=markdownLinkDelimiter start="\[\[" end="\]\]" contains=markdownUrl keepend oneline concealends
" markdownLinkText is copied from runtime files with 'concealends' appended
syn region markdownLinkText matchgroup=markdownLinkTextDelimiter start="!\=\[\%(\%(\_[^][]\|\[\_[^][]*\]\)*]\%( \=[[(]\)\)\@=" end="\]\%( \=[[(]\)\@=" nextgroup=markdownLink,markdownId skipwhite contains=@markdownInline,markdownLineStart concealends
" markdownLink is copied from runtime files with 'conceal' appended
syn region markdownLink matchgroup=markdownLinkDelimiter start="(" end=")" contains=markdownUrl keepend contained conceal
```

You can then enable conceal with `:setlocal conceallevel=2`, see
`:h 'conceallevel'`.

Note that if you are using `nvim-treesitter` for Markdown, don't forget to
enable `additional_vim_regex_highlighting`:

```lua
require("nvim-treesitter.configs").setup({
  -- ...
  highlight = {
    -- ...
    additional_vim_regex_highlighting = { "markdown" }
  },
})
```

## Troubleshooting With a Minimal Config

If there are issues, you can test with a minimal config to rule out other
players.

Make a new directory, `init-zk` and make a fresh zk notebook. The structure of
`init-zk` should look as follows:

```text
.
├── init.lua
└── notebook
    └── .zk
        ├── config.toml
        ├── notebook.db
        └── templates
            └── default.md
```

Paste the following into `init.lua`:

```lua
-- Redirect Neovim runtime paths to /tmp
vim.env.XDG_CONFIG_HOME = "/tmp/nvim/config"
vim.env.XDG_DATA_HOME = "/tmp/nvim/data"
vim.env.XDG_STATE_HOME = "/tmp/nvim/state"
vim.env.XDG_CACHE_HOME = "/tmp/nvim/cache"

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- Load plugins
require("lazy").setup({
  {
    "neovim/nvim-lspconfig",
  },
	{
		"zk-org/zk-nvim",
		config = function()
      vim.lsp.enable("zk") -- required as of neovim 0.11
			require("zk").setup()
		end,
	}
})
```

Then change this line in `.zk/config.toml`

```toml
[tool]
# editor = "vim"
editor = "nvim -u ~/path/to/init-zk/init.lua"
```

## Telescope Plugin

> Not recommended, instead just use the
> [:ZkNotes or :ZkTags commands](#built-in-commands).

It's possible (but not required) to also load the notes and tags pickers as a
telescope plugin.

```lua
require("telescope").load_extension("zk")
```

```vim
:Telescope zk notes
:Telescope zk notes createdAfter=3\ days\ ago
:Telescope zk tags
:Telescope zk tags created=today
```
