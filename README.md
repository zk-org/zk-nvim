# zk-nvim
Neovim extension for zk

## Telescope

> Only works in buffers where the `zk` language server (LSP) is attached.

### Setup
```lua
require("telescope").load_extension("zk")
```

### Commands
```vim
:Telescope zk notes
:Telescope zk tags
:Telescope zk backlinks
```

### Example Mapping
```lua
vim.api.nvim_set_keymap(
  "n",
  "<Leader>fz",
  "<cmd>lua require('telescope').extensions.zk.notes()<CR>",
  {noremap = true}
)
```
