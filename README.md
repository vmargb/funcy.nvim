# funcy.nvim
> [!WARNING]
> This plugin is in early alpha stage and is not ready for use.

A snippets plugin for function definitions using plain Lua

## Installation

## Lazy
```lua
{
    "vmargb/funcy.nvim",
    config = function()
        require("funcy").setup({
            insert_strategy = "before_cursor",
        })
    end
}
```

## Packer

```lua
use {
    "vmargb/funcy.nvim",
    config = function()
        require("funcy").setup({
            insert_strategy = "before_cursor",
        })
    end
}
```

## Setup
