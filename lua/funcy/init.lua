local templates = require('config.templates') -- language templates local utility = require('utility') -- helper functions
local utility = require('utility')
local default_config = require('config.config')

local funcy = {
    config = default_config,
}

function funcy.setup(user_config)
    -- change defaults
    funcy.config = vim.tbl_extend("force", funcy.config, user_config or {})
end

local function prompt_for_types(args)
    local types = {}
    for _, arg in ipairs(args) do
        local input_type = vim.fn.input("Type for " .. arg .. ": ")
        table.insert(types, input_type)
    end
    return types
end

local function extract_function_info(line)
    local function_name, args_str = line:match("([%w_]+)%s*%((.*)%)")
    if not function_name or not args_str then
        print("Invalid function call format.")
        return nil, nil
    end

    local args, types = {}, {}
    local pattern = '[^,]+' -- Default pattern for non-quoted arguments

    for arg in args_str:gmatch(pattern) do
        arg = arg:match('^%s*(.-)%s*$') -- Trim whitespace
        local name, type_hint
        --
        -- Check if the argument is quoted
        if arg:sub(1,1) == '"' and arg:sub(-1) == '"' then
            name = arg
            type_hint = ""
        else
            name, type_hint = arg:match("([^:]+):?(%w*)")
        end

        table.insert(args, name)
        table.insert(types, type_hint ~= "" and type_hint or nil)
    end

    return function_name, args, types
end

-- Function to determine where to insert the function definition
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

local function generate_function_definition(function_name, args, types)
    local filetype = vim.api.nvim_buf_get_option(0, "filetype")
    local template = templates[filetype] or templates.default
    if not template then
        print("Unsupported filetype: " .. filetype)
        return nil
    end

    -- prompt for types
    if template.type_sensitive and not types then
        types = prompt_for_types(args)
    end

    local params = generate_params(args)

    local formatted_params = utility.format_params(params, types, filetype)
    local indent = string.rep(" ", vim.api.nvim_buf_get_option(0, "shiftwidth"))
    local function_def = string.format(template.header, function_name, formatted_params)

    -- Generate function body
    for _, arg in ipairs(args) do
        function_def = function_def .. string.format(template.body, indent, arg)
    end
    function_def = function_def .. template.footer

    return function_def
end

-- Main function to create the function
function funcy.create_function()
    local line = vim.api.nvim_get_current_line()
    local function_name, args = extract_function_info(line)
    if not function_name then return end
    -- Try to extract types from the current context
    local current_line_num = vim.api.nvim_win_get_cursor(0)[1]
    local types = utility.extract_types(args, current_line_num)

    local function_def = generate_function_definition(function_name, args, types)
    if not function_def then return end

    local insert_line_num = find_insert_position(funcy.config.insert_strategy)
    local function_lines = vim.split(function_def, "\n", true)

    vim.api.nvim_buf_set_lines(0, insert_line_num, insert_line_num, false, function_lines)
    -- set the cursor to the first parameter
    vim.api.nvim_win_set_cursor(0, { insert_line_num + 1, 0 })
end

function funcy.create_functions()
    local start_line, end_line = vim.fn.line("'<"), vim.fn.line("'>")
    local insert_line_num = find_insert_position(funcy.config.insert_strategy)
    local function_lines = {}

    for i = start_line, end_line do
        local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
        local function_name, args = extract_function_info(line)
        if function_name and args then
            -- Try to extract types from the current context
            local types = utility.extract_types(args, i)

            local function_def = generate_function_definition(function_name, args, types)
            if function_def then
                vim.list_extend(function_lines, vim.split(function_def, "\n", true))
                vim.list_extend(function_lines, { "" }) -- Add a blank line between functions
            end
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
-- my_function3(arg5, arg6)
-- my_function4(1, 2)
-- my_function4("hello", "world")
-- my_function4('hello', 'world')
