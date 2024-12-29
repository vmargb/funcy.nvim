# funcy.nvim
> [!WARNING]
> This plugin is in early development and may be subject to breaking changes.

`funcy.nvim` lets you easily create function definitions using Regex and LSP.

## 🌟 Features
- **Function completions**: generate definitions from function calls (wip)
- **Variable completions**: create undeclared variables (TODO)
- **Tabstops with Tab**: repeatable jumps to next placeholder (wip)

## 📦 Installation

### [Lazy](https://github.com/folke/lazy.nvim)
```lua
{
    "vmargb/funcy.nvim",
    lazy = true,
    dependencies = { "neovim/nvim-lspconfig" },
    config = function()
        require("funcy").setup()
    end,
}
```

### [Packer](https://github.com/wbthomason/packer.nvim)
```lua
use {
    "vmargb/funcy.nvim",
    dependencies = { "neovim/nvim-lspconfig" },
    config = function()
        require("funcy").setup()
    end,
}
```

## ⚙️ Configuration
```lua
require("vmargb/funcy.nvim").setup({
  insert_strategy = "end",
  use_arg_names = true,
  prompt_for_types = true,
  enable_tabstops = true,
})
```

## 🚀 Usage
- `<leader>cf`: Create function
- `visual+<leader>cf`: Create functions with visual mode
