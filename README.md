# funcy.nvim
> [!WARNING]
> This plugin is in early development and may be subject to breaking changes.

A snippets plugin for function definitions using Regex and LSP.

## 📦 Installation

### [Lazy](https://github.com/folke/lazy.nvim)
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

### [Packer](https://github.com/wbthomason/packer.nvim)
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
`<leader>cf` - Create function
`visual+<leader>cf` - Create multiple functions with visual mode

## Configuration
### Default Options

```lua
require("vmargb/funcy.nvim").setup({
  insert_strategy = "before_cursor",
  use_arg_names = true,
})

