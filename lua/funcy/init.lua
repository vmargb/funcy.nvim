local utility = require('utility')
local default_config = require('config.config')
local parser = require('function_parser')
local tabstop = require('tabstop')
local generator = require('generator')

local funcy = {
    config = default_config.defaults,
}

---@param user_config table
function funcy.setup(user_config)
    -- change defaults
    funcy.config = vim.tbl_extend("force", funcy.config, user_config or {})
end

---@param function_name string
---@param args table
---@param line string
---@param insert_line_num number
---@return string[], table
local function generate_function_definition(function_name, args, line, insert_line_num)
    local filetype = vim.api.nvim_buf_get_option(0, "filetype")
    local template = utility.template(filetype)

    local params, known_types = parser.generate_params(args) -- param names
    local types = parser.extract_arg_types(args, filetype, known_types)
    local return_type = parser.extract_return_type(line, filetype) or template.default_type

    local function_def, placeholders = generator.format_function(
        function_name, params, types, return_type, template, insert_line_num
    )
    local function_lines = vim.split(function_def, "\n", true)

    return function_lines, placeholders
end

-- where to insert the generated function
---@param strategy string
---@return number
local function find_insert_position(strategy)
    local current_line_num = vim.api.nvim_win_get_cursor(0)[1]
    local buffer_len = vim.api.nvim_buf_line_count(0)

    local filetype = vim.bo.filetype
    local template = utility.template(filetype)

    local is_function_def = template.header:match("^%s*[%w_:]+") or "^%s*function"
    local is_class_def = "^%s*class%s" -- Extendable for more precise class patterns per filetype
    local scope_end_pattern = template.footer:match("^%s*%}") or "^%s*end$"

    if strategy == "before_cursor" then
        -- find an empty line before the cursor
        local empty_line = utility.find_empty_line_before(current_line_num)
        if empty_line and not utility.has_function_between(empty_line, current_line_num - 1) then
            return empty_line
        end
        -- default to the cursor position if no empty line
        return current_line_num
    elseif strategy == "in_scope" then
        -- find the start of the current scope
        local scope_start = nil
        for i = current_line_num, 1, -1 do
            local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
            if line:match(is_function_def) or line:match(is_class_def) then
                scope_start = i
                break
            end
        end

        -- if scope start is found, find the end of the scope
        if scope_start then
            for i = scope_start + 1, buffer_len do
                local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
                if line:match("^%s*$") or line:match(scope_end_pattern) then
                    return i
                end
            end
            -- if no scope end is found, default to scope start
            return scope_start
        end
    end

    -- default to the end of the file
    return buffer_len
end

-- Main function to create the function
---@param mode string
function funcy.create_function(mode)
    local filetype = vim.api.nvim_buf_get_option(0, "filetype")
    local insert_line_num = find_insert_position(funcy.config.insert_strategy)
    local function_lines = {}
    local all_placeholders = {}

    if mode == "visual" then
        local start_line, end_line = vim.fn.line("'<"), vim.fn.line("'>")
        for i = start_line, end_line do
            local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
            vim.api.nvim_win_set_cursor(0, { i, 0 }) -- Explicitly set cursor to this line for LSP to work
            local function_name, args = parser.extract_function_info(line)
            if function_name then
                local function_def, placeholders = generate_function_definition(function_name, args, line, insert_line_num)
                if function_def then
                    vim.list_extend(function_lines, function_def)
                    vim.list_extend(all_placeholders, placeholders)
                    vim.list_extend(function_lines, { "" })
                end
            end
        end
    else
        local line = vim.api.nvim_get_current_line()
        local function_name, args = parser.extract_function_info(line)
        if not function_name then return end
        local function_def, placeholders = generate_function_definition(function_name, args, line, insert_line_num)
        if function_def and placeholders then
            function_lines = function_def
            all_placeholders = placeholders
        end
    end

    if #function_lines > 0 then
        vim.api.nvim_buf_set_lines(0, insert_line_num, insert_line_num, false, function_lines)
        vim.api.nvim_win_set_cursor(0, { insert_line_num + 1, 0 })

        if #all_placeholders > 0 then
            tabstop.set_placeholders(all_placeholders)
            print("Placeholders set. Press <Tab> to jump.")
        else
            print("No placeholders found.")
        end
    else
        print("No valid function calls found.")
    end
end

---@param strategy string
function funcy.set_strategy(strategy)
    funcy.config.insert_strategy = strategy
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
vim.api.nvim_set_keymap("n", "<Tab>", "<Cmd>lua require('tabstop').jump_to_next()<CR>", { noremap = true, silent = true })

-- Example for testing:
-- my_function1(arg1, arg2)
-- my_function2(arg3, arg4)
-- my_function3(1, 2)
-- my_function4("hello", "world")
-- my_function5('hello', 'world')
