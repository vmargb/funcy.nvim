local templates = {
    default = {
        header = "%s(%s) {\n",
        body = "%s// %s = ...\n",
        footer = "}\n",
        type_sensitive = false
    },
    lua = {
        header = "function %s(%s)\n",
        body = "%s-- %s = ...\n",
        footer = "end\n",
        type_sensitive = false
    },
    python = {
        header = "def %s(%s):\n",
        body = "%s# %s = ...\n",
        footer = "    pass\n",
        type_sensitive = false
    },
    javascript = {
        header = "function %s(%s) {\n",
        body = "%s// %s = ...\n",
        footer = "}\n",
        type_sensitive = false
    },
    typescript = {
        header = "function %s(%s): void {\n",
        body = "%s// %s = ...\n",
        footer = "}\n",
        type_sensitive = false,
        default_type = "any"
    },
    java = {
        header = "public static void %s(%s) {\n",
        body = "%s// %s = ...\n",
        footer = "}\n",
        type_sensitive = true,
        default_type = "Object"
    },
    c = {
        header = "void %s(%s) {\n",
        body = "%s// %s = ...\n",
        footer = "}\n",
        type_sensitive = true,
        default_type = "void"
    },
    cpp = {
        header = "void %s(%s) {\n",
        body = "%s// %s = ...\n",
        footer = "}\n",
        type_sensitive = true,
        default_type = "void"
    },
    csharp = {  -- C#
        header = "public static void %s(%s) {\n",
        body = "%s// %s = ...\n",
        footer = "}\n",
        type_sensitive = true
    },
    go = {
        header = "func %s(%s) {\n",
        body = "%s// %s = ...\n",
        footer = "}\n",
        type_sensitive = true
    },
    ruby = {
        header = "def %s(%s)\n",
        body = "%s# %s = ...\n",
        footer = "end\n",
        type_sensitive = true
    },
    php = {
        header = "function %s(%s) {\n",
        body = "%s// %s = ...\n",
        footer = "}\n",
        type_sensitive = false
    },
    rust = {
        header = "fn %s(%s) {\n",
        body = "%s// %s = ...\n",
        footer = "}\n",
        type_sensitive = true
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
    }
}

return templates
