# zk-nvim
Neovim extension for zk.

## Requirements

There are some hard and soft requirements with this plugin:

* **ONLY** Neovim is supported
* Zk must be installed already

## Installation

Use your favorite way of managing packages.

For example, with paq:

```lua
require 'paq' {
  'mickael-menu/zk-nvim';
}
```

## Set Up

To use and set up this plugin (assuming in `init.lua`):

```lua
local zk = require 'zk-nvim'
zk.setup()
```

## Configuration

You can pass a table to `setup` for some configuration:

```lua
{
    -- The ZK binary
    bin = 'zk',

    -- How to open notes (vsplit, edit, etc...)
    open_mode = 'edit',

    -- Where the ZK log file should exist (provides LSP info)
    log_file = '/tmp/zk-lsp.log',
}
```
