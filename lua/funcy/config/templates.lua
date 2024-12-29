local templates = {
    default = {
        header = "%s %s(%s) {\n", -- Added %s for return type
        body = "%s// %s = %s\n",
        footer = "}\n",
        type_sensitive = false,
        var_pattern = "^%s*[%w_:]+%s+",
        type_pos = "start", -- Default: return type at the start
        default_type = "any",      -- Added default type
        type_separator = " "
    },
    lua = {
        header = "function %s(%s)\n", -- No explicit return type in Lua
        body = "%s-- %s = %s\n",
        footer = "end\n",
        type_sensitive = false,
        type_pos = "end" -- Can use type hints with comments
    },
    javascript = {
        header = "function %s(%s) {\n", -- No explicit return type in JS
        body = "%s// %s = %s\n",
        footer = "}\n",
        type_sensitive = false,
        type_pos = "end" -- For JSDoc style type hints
    },
    cpp = {
        header = "%s %s(%s) {\n", -- Added %s for return type
        body = "%s// %s = %s\n",
        footer = "}\n",
        type_sensitive = true,
        default_type = "void",
        var_pattern = "^%s*([%w_:]*)%s*([%w_]+)%s*[=;]",
        type_pos = "start",
        type_separator = " ",
    },
    csharp = {
        header = "public static %s %s(%s) {\n", -- Added %s for return type
        body = "%s// %s = %s\n",
        footer = "}\n",
        type_sensitive = true,
        default_type = "void",          -- Added default type
        type_pos = "start"
    },
    java = {
        header = "public static %s %s(%s) {\n", -- Added %s for return type
        body = "%s// %s = %s\n",
        footer = "}\n",
        type_sensitive = true,
        default_type = "Object",
        var_pattern = "^%s*([%w_<>%[%]]+)%s+([%w_]+)%s*[=;]",
        type_pos = "start",
    },
    python = {
        header = "def %s(%s):\n", -- No explicit return type in Python
        body = "%s# %s = %s\n",
        footer = "    pass\n",
        type_sensitive = false,
        var_pattern = "^%s*([%w_]+)%s*:%s*([%w_%.]+)", -- for type hints
        type_pos = "end", -- For type hints after the function signature
        type_separator = ":",
        return_separator = " -> ",
    },
    typescript = {
        header = "function %s(%s): %s {\n", -- Added %s for return type
        body = "%s// %s = %s\n",
        footer = "}\n",
        type_sensitive = false,
        default_type = "any",
        var_pattern = "^%s*(?:let|const|var)%s+([%w_]+)%s*:%s*([%w_<>%[%]]+)",
        type_pos = "end", -- Between function name and parameters
        type_separator = ":",
    },
    go = {
        header = "func %s(%s) %s {\n", -- Added %s for return type
        body = "%s// %s = %s\n",
        footer = "}\n",
        type_sensitive = true,
        default_type = "interface{}", -- Added default type
        var_pattern = "^%s*(?:var%s+)?([%w_]+)%s+([%w_]+)%s*[=:;]",
        type_pos = "end", -- After the parameter list
        type_separator = " ",
    },
    rust = {
        header = "fn %s(%s) -> %s {\n", -- Added -> %s for return type
        body = "%s// %s = %s\n",
        footer = "}\n",
        type_sensitive = true,
        default_type = "()",       -- Added default type
        var_pattern = "^%s*let%s+(?:mut%s+)?([%w_]+)%s*:%s*([%w_<>]+)",
        type_pos = "end", -- Between function name and parameters (for function definitions)
        type_separator = ":",
    },
    swift = {
        header = "func %s(%s) -> %s {\n", -- Added -> %s for return type
        body = "%s// %s = %s\n",
        footer = "}\n",
        type_sensitive = true,
        default_type = "Void",     -- Added default type
        type_pos = "end" -- After the parameter list, using ->
    },
    kotlin = {
        header = "fun %s(%s): %s {\n", -- Added : %s for return type
        body = "%s// %s = %s\n",
        footer = "}\n",
        type_sensitive = true,
        default_type = "Unit",     -- Added default type
        type_pos = "end" -- After the parameter list, using :
    },
    scala = {
        header = "def %s(%s): %s = {\n", -- Added : %s for return type
        body = "%s// %s = %s\n",
        footer = "}\n",
        type_sensitive = true,
        default_type = "Unit",     -- Added default type
        type_pos = "end" -- Between function name and parameters, using :
    },
}

return templates
