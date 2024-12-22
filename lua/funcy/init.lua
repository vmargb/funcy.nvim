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

-- where to insert the function definition
local function find_insert_position(strategy)
    local current_line_num = vim.api.nvim_win_get_cursor(0)[1]
    -- this line is to get the number of lines in the buffer
    local buffer_len = vim.api.nvim_buf_line_count(0)
    local insert_line_num = buffer_len -- Default to end of file

    if strategy == "before_cursor" then
        -- Find an empty line before the current line
        local empty_line = utility.find_empty_line_before(current_line_num)
        if empty_line and not utility.has_function_between(empty_line, current_line_num - 1) then
            return empty_line
        end
        -- Fallback to the current cursor position if no suitable empty line is found
        return current_line_num
    elseif strategy == "in_scope" then
        -- Find the start and end of the current scope
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

local function generate_params(args)
    local params = {}

    for i = 1, #args do
        local param
        local arg = args[i]

        -- Check if arg is a string with quotes
        local is_quoted_string = type(arg) == "string" and (arg:match('^".*"$') or arg:match("^'.*'$"))
        -- Check if arg is a number (integer or float)
        local is_number = type(arg) == "number"
        -- Check if arg is a string representation of a number
        local is_number_string = type(arg) == "string" and tonumber(arg) ~= nil
        local is_primitive = is_quoted_string or is_number or is_number_string

        if is_primitive then
            param = i <= 26 and string.char(96 + i) or ("arg" .. i)
        else
            param = arg
        end

        table.insert(params, param)
    end

    return params
end

local function generate_function_definition(function_name, args, line)
    local filetype = vim.api.nvim_buf_get_option(0, "filetype")
    local template = utility.template(filetype)
    if not template then
        print("Unsupported filetype: " .. filetype)
        return nil
    end

    local types = parser.extract_arg_types(args, filetype)
    local return_type = parser.extract_return_type(line, filetype)

    -- prompt for types if no types
    if template.type_sensitive then
        if not types then
            types = parser.prompt_for_types(args)
        end
        -- prompt for return type if no return types
        if not return_type then
            -- add a parser.prompt_for_return_type if you want to prompt the user
            return_type = template.default_type
        end
    end

    local params = generate_params(args) -- param names

    local indent = string.rep(" ", vim.api.nvim_buf_get_option(0, "shiftwidth"))
    -- format template header to include function name, params and return type
    local function_def = utility.format_header(function_name, params, types, return_type, filetype)

    -- Generate function body
    for _, arg in ipairs(args) do
        function_def = function_def .. string.format(template.body, indent, arg)
    end
    function_def = function_def .. template.footer

    return function_def
end

-- Main function to create the function
function funcy.create_function()
    local filetype = vim.api.nvim_buf_get_option(0, "filetype")
    local line = vim.api.nvim_get_current_line()
    local insert_line_num = find_insert_position(funcy.config.insert_strategy)
    local function_name, args = parser.extract_function_info(line)
    if not function_name then return end
    local function_def = generate_function_definition(function_name, args, line)
    if not function_def then return end

    local function_lines = vim.split(function_def, "\n", true)

    vim.api.nvim_buf_set_lines(0, insert_line_num, insert_line_num, false, function_lines)
    vim.api.nvim_win_set_cursor(0, { insert_line_num + 1, 0 }) -- set the cursor to the first def
end

function funcy.create_functions()
    local filetype = vim.api.nvim_buf_get_option(0, "filetype")
    local start_line, end_line = vim.fn.line("'<"), vim.fn.line("'>")
    --print("Start Line:", start_line, "End Line:", end_line)
    local insert_line_num = find_insert_position(funcy.config.insert_strategy)
    local function_lines = {}

    for i = start_line, end_line do
        local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
        --print("Line", i, ":", line)
        local function_name, args = parser.extract_function_info(line)
        if not function_name then return end
        local function_def = generate_function_definition(function_name, args, line)
        if function_def then
            vim.list_extend(function_lines, vim.split(function_def, "\n", true))
            vim.list_extend(function_lines, { "" }) -- Add a blank line between functions
        end
    end

    if #function_lines > 0 then
        vim.api.nvim_buf_set_lines(0, insert_line_num, insert_line_num, false, function_lines)
        vim.api.nvim_win_set_cursor(0, { insert_line_num + 1, 0 })
    else
        print("No valid function calls found in the selected lines.")
    end
end

vim.api.nvim_create_user_command("SetCallStrategy", function(opts)
    funcy.set_strategy(opts.args)
end, { nargs = 1 })

vim.api.nvim_create_user_command("CreateFunc", function()
    print(1)
    funcy.create_function()
end, { nargs = 0 })

vim.api.nvim_create_user_command("CreateFuncs", function()
    funcy.create_functions()
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
