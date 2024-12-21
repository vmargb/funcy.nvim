local templates = {
    default = {
        header = "%s(%s) {\n",
        body = "%s// %s = ...\n",
        footer = "}\n",
        type_sensitive = false,
        var_patter = "^%s*[%w_:]+%s+"
    },
    lua = {
        header = "function %s(%s)\n",
        body = "%s-- %s = ...\n",
        footer = "end\n",
        type_sensitive = false
    },
    javascript = {
        header = "function %s(%s) {\n",
        body = "%s// %s = ...\n",
        footer = "}\n",
        type_sensitive = false
    },
    cpp = {
        header = "void %s(%s) {\n",
        body = "%s// %s = ...\n",
        footer = "}\n",
        type_sensitive = true,
        default_type = "void",
        var_pattern = "^%s*([%w_:]+)%s+([%w_]+)%s*[=;]"
    },
    csharp = {
        header = "public static void %s(%s) {\n",
        body = "%s// %s = ...\n",
        footer = "}\n",
        type_sensitive = true
    },
    java = {
        header = "public static void %s(%s) {\n",
        body = "%s// %s = ...\n",
        footer = "}\n",
        type_sensitive = true,
        default_type = "Object",
        var_pattern = "^%s*([%w_<>%[%]]+)%s+([%w_]+)%s*[=;]"
    },
    python = {
        header = "def %s(%s):\n",
        body = "%s# %s = ...\n",
        footer = "    pass\n",
        type_sensitive = false,
        var_pattern = "^%s*([%w_]+)%s*:%s*([%w_%.]+)"  -- for type hints
    },
    typescript = {
        header = "function %s(%s): void {\n",
        body = "%s// %s = ...\n",
        footer = "}\n",
        type_sensitive = false,
        default_type = "any",
        var_pattern = "^%s*(?:let|const|var)%s+([%w_]+)%s*:%s*([%w_<>%[%]]+)"
    },
    go = {
        header = "func %s(%s) {\n",
        body = "%s// %s = ...\n",
        footer = "}\n",
        type_sensitive = true,
        var_pattern = "^%s*(?:var%s+)?([%w_]+)%s+([%w_]+)%s*[=:;]"
    },
    rust = {
        header = "fn %s(%s) {\n",
        body = "%s// %s = ...\n",
        footer = "}\n",
        type_sensitive = true,
        var_pattern = "^%s*let%s+(?:mut%s+)?([%w_]+)%s*:%s*([%w_<>]+)"
    },
    swift = {
        header = "func %s(%s) {\n",
        body = "%s// %s = ...\n",
        footer = "}\n",
        type_sensitive = true
    },
    kotlin = {
        header = "fun %s(%s) {\n",
        body = "%s// %s = ...\n",
        footer = "}\n",
        type_sensitive = true
    },
    scala = {
        header = "def %s(%s): Unit = {\n",
        body = "%s// %s = ...\n",
        footer = "}\n",
        type_sensitive = true
    },
}

return templates
