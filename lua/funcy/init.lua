local templates = require('templates') -- language templates

local funcy = {
    config = {
        insert_strategy = "before_cursor", -- Default strategy: "end", "before_cursor", "in_scope"
    }
}

function funcy.setup()
    -- configuration
    funcy.config = vim.tbl_extend("force", funcy.config, user_config or {})
end

local function extract_function_info(line)
    local function_name, args_str = line:match("([%w_]+)%s*%((.*)%)")

    if not function_name or not args_str then
        print("Invalid function call format.")
        return nil
    end

    local args = {}
    for arg in args_str:gmatch("[^,]+") do
        local name = arg:match("%s*(%w+)")
        if name then
            table.insert(args, name)
        end
    end

    return function_name, args
end

-- Function to generate the function definition based on filetype
local function generate_function_definition(function_name, args)
    local filetype = vim.api.nvim_buf_get_option(0, "filetype")
    local template = templates[filetype]
    if not template then
        print("Unsupported filetype: " .. filetype)
        return nil
    end

    local params = {}
    for i = 1, #args do
        local param = string.char(96 + i)  -- 97 is ASCII for 'a'
        table.insert(params, param)
    end

    local indent = string.rep(" ", vim.api.nvim_buf_get_option(0, 'shiftwidth'))
    local function_def = string.format(template.header, function_name, table.concat(params, ", "))

    -- function body
    for i, param_name in ipairs(params) do
        function_def = function_def .. string.format(template.body, indent, param_name)
    end

    function_def = function_def .. template.footer
    return function_def
end

-- my_function2(arg3, arg4)

-- Function to determine where to insert the function definition
local function find_insert_position(strategy)
    local current_line_num = vim.api.nvim_win_get_cursor(0)[1]
    -- this line is to get the number of lines in the buffer
    local buffer_len = vim.api.nvim_buf_line_count(0)
    local insert_line_num = buffer_len -- Default to end of file

    if strategy == "before_cursor" then
        return current_line_num
    elseif strategy == "in_scope" then
        -- Using Treesitter or regex-based logic for language-aware placement
        local scope_start = nil
        local scope_end = nil
        for i = current_line_num, 1, -1 do
            local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
            if line:match("^class ") or line:match("^function ") or line:match("^def ") then
                scope_start = i
                break
            end
        end
        if scope_start then
            for i = scope_start + 1, buffer_len do
                local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
                if line:match("^%s*end$") or line:match("^%s*$") then
                    scope_end = i
                    break
                end
            end
        end
        if scope_end then
            insert_line_num = scope_end
        else
            insert_line_num = scope_start or buffer_len
        end
    end

    return insert_line_num
end

-- Main function to create the function
function funcy.create_function()
    local line = vim.api.nvim_get_current_line()
    local function_name, args = extract_function_info(line)
    if not function_name then return end

    local function_def = generate_function_definition(function_name, args)
    if not function_def then return end

    local insert_line_num = find_insert_position(funcy.config.insert_strategy)

    local function_lines = vim.split(function_def, "\n", true)
    vim.api.nvim_buf_set_lines(0, insert_line_num - 1, insert_line_num - 1, false, function_lines)

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
            local function_def = generate_function_definition(function_name, args)
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
