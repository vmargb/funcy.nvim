local M = {}

M.defaults = {
    insert_strategy = "before_cursor", -- Default strategy: "end", "before_cursor", "in_scope"
    use_arg_names = true,
    prompt_for_types = true, -- disable to use default types
}

return M
