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
  insert_strategy = "before_cursor",
  use_arg_names = true,
  prompt_for_types = true,
})
```

## 🚀 Usage
- `<leader>cf`: Create function
- `visual+<leader>cf`: Create functions with visual mode
