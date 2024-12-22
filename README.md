# funcy.nvim
> [!WARNING]
> This plugin is in early development stage and is not ready for use.

A snippets plugin for function definitions using plain Lua and LSP.

## 📦 Installation

### Lazy
```lua
{
    "vmargb/funcy.nvim",
    lazy = true,
    config = function()
        require("funcy").setup()
    end,
    dependencies = { "neovim/nvim-lspconfig" }
}
```

### Packer

```lua
use {
    "vmargb/funcy.nvim",
    config = function()
        require("funcy").setup()
    end,
    dependencies = { "neovim/nvim-lspconfig" }
}
```

## Usage
### Commands

## Configuration
### Default Options

```lua
require("vmargb/funcy.nvim").setup({
  insert_strategy = "before_cursor",
  use_arg_names = true,
})

