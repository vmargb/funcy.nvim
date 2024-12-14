local templates = {
    lua = {
        header = "function %s(%s)\n",
        body = "%s-- %s = ...\n",
        footer = "end\n"
    },
    python = {
        header = "def %s(%s):\n",
        body = "%s# %s = ...\n",
        footer = "    pass\n" 
    },
    javascript = {
        header = "function %s(%s) {\n",
        body = "%s// %s = ...\n",
        footer = "}\n"
    },
    typescript = {
        header = "function %s(%s): void {\n", 
        body = "%s// %s = ...\n",
        footer = "}\n"
    },
    java = {
        header = "public static void %s(%s) {\n", 
        body = "%s// %s = ...\n",
        footer = "}\n"
    },
    c = {
        header = "void %s(%s) {\n",
        body = "%s// %s = ...\n",
        footer = "}\n"
    },
    cpp = {
        header = "void %s(%s) {\n",
        body = "%s// %s = ...\n",
        footer = "}\n"
    },
    csharp = {  -- C#
        header = "public static void %s(%s) {\n",
        body = "%s// %s = ...\n",
        footer = "}\n"
    },
    go = {
        header = "func %s(%s) {\n",
        body = "%s// %s = ...\n",
        footer = "}\n"
    },
    ruby = {
        header = "def %s(%s)\n",
        body = "%s# %s = ...\n",
        footer = "end\n"
    },
    php = {
        header = "function %s(%s) {\n",
        body = "%s// %s = ...\n",
        footer = "}\n"
    },
    rust = {
        header = "fn %s(%s) {\n",
        body = "%s// %s = ...\n",
        footer = "}\n"
    },
    swift = {
        header = "func %s(%s) {\n",
        body = "%s// %s = ...\n",
        footer = "}\n"
    },
    kotlin = {
        header = "fun %s(%s) {\n",
        body = "%s// %s = ...\n",
        footer = "}\n"
    },
    scala = {
        header = "def %s(%s): Unit = {\n",
        body = "%s// %s = ...\n",
        footer = "}\n"
    }
}

return templates
