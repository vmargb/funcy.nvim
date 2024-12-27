local utility = require('utility')
local default_config = require('config.config')
local parser = require('function_parser')

local funcy = {
    config = default_config,
}

function funcy.setup(user_config)
    -- change defaults
    funcy.config = vim.tbl_extend("force", funcy.config, user_config or {})
end

-- where to insert the generated function
local function find_insert_position(strategy)
    local current_line_num = vim.api.nvim_win_get_cursor(0)[1]
    local buffer_len = vim.api.nvim_buf_line_count(0)
    local insert_line_num = buffer_len -- Default to end of file

    if strategy == "before_cursor" then
        local empty_line = utility.find_empty_line_before(current_line_num)
        if empty_line and not utility.has_function_between(empty_line, current_line_num - 1) then
            return empty_line
        end
        -- default to cursor position if nothing is found
        return current_line_num
    elseif strategy == "in_scope" then
        -- find the start and end of the current scope
        local scope_start, scope_end = nil, nil
        for i = current_line_num, 1, -1 do
            local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
            if utility.is_function_definition(line) or line:match("^%s*class ") then
                scope_start = i
                break
            end
        end
        if scope_start then
            for i = scope_start + 1, buffer_len do
                local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
                if utility.is_empty_line(line) or line:match("^%s*end$") then
                    scope_end = i
                    break
                end
            end
        end
        if scope_end then
            return scope_end
        else
            return scope_start or buffer_len
        end
    end

    -- default to the end of the file
    return buffer_len
end

local function generate_function_definition(function_name, args, line)
    local filetype = vim.api.nvim_buf_get_option(0, "filetype")
    local template = utility.template(filetype)
    if not template then
        print("Unsupported filetype: " .. filetype)
        return nil
    end

    local params, known_types = parser.generate_params(args) -- param names
    local types = parser.extract_arg_types(args, filetype, known_types) -- here
    local return_type = parser.extract_return_type(line, filetype)

    -- prompt for types if no types
    if template.type_sensitive then
        if not types and #args > 0 then
            types = parser.prompt_for_types(args)
        end
        -- prompt for return type if no return types
        if not return_type then
            -- add a parser.prompt_for_return_type if you want to prompt the user
            return_type = template.default_type
        end
    end

    local indent = string.rep(" ", vim.api.nvim_buf_get_option(0, "shiftwidth"))
    -- format template header to include function name, params and return type
    local function_def = utility.format_header(function_name, params, types, return_type, filetype)

    -- add body to header
    for _, arg in ipairs(args) do
        function_def = function_def .. string.format(template.body, indent, arg)
    end
    function_def = function_def .. template.footer

    return function_def
end

-- Main function to create the function
function funcy.create_function(mode)
    local filetype = vim.api.nvim_buf_get_option(0, "filetype")
    local insert_line_num = find_insert_position(funcy.config.insert_strategy)
    local function_lines = {}

    if mode == "visual" then
        local start_line, end_line = vim.fn.line("'<"), vim.fn.line("'>")
        for i = start_line, end_line do
            local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
            vim.api.nvim_win_set_cursor(0, { i, 0 }) -- Explicitly set cursor to this line for LSP to work
            local function_name, args = parser.extract_function_info(line)
            if function_name then
                local function_def = generate_function_definition(function_name, args, line)
                if function_def then
                    vim.list_extend(function_lines, vim.split(function_def, "\n", true))
                    vim.list_extend(function_lines, { "" }) -- Add a blank line between functions
                end
            end
        end
    else
        local line = vim.api.nvim_get_current_line()
        local function_name, args = parser.extract_function_info(line)
        if not function_name then return end
        local function_def = generate_function_definition(function_name, args, line)
        if function_def then
            function_lines = vim.split(function_def, "\n", true)
        end
    end

    if #function_lines > 0 then
        vim.api.nvim_buf_set_lines(0, insert_line_num, insert_line_num, false, function_lines)
        vim.api.nvim_win_set_cursor(0, { insert_line_num + 1, 0 }) -- Set cursor to the first line of the inserted function
    else
        print("No valid function calls found.")
    end
end

vim.api.nvim_create_user_command("SetCallStrategy", function(opts)
    funcy.set_strategy(opts.args)
end, { nargs = 1 })

vim.api.nvim_create_user_command("CreateFunc", function()
    funcy.create_function("normal")
end, { nargs = 0 })

vim.api.nvim_create_user_command("CreateFuncs", function()
    funcy.create_function("visual")
end, { nargs = 0, range = true })

-- mappings
vim.api.nvim_set_keymap("n", "<leader>cf", ":CreateFunc<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<leader>cf", ":CreateFuncs<CR>", { noremap = true, silent = true })

-- Example for testing:
-- my_function1(arg1, arg2)
-- my_function2(arg3, arg4)
-- my_function3(1, 2)
-- my_function4("hello", "world")
-- my_function5('hello', 'world')
