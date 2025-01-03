local util = require('utility')

local M = {}

---@param args table
function M.prompt_for_types(args)
    local types = {}
    for _, arg in ipairs(args) do
        local input_type = vim.fn.input("Type for " .. arg .. ": ")
        table.insert(types, input_type)
    end
    return types
end

---@param line string
function M.extract_function_info(line)
    local function_name, args_str = line:match("([%w_%.]+)%s*%((.-)%)")
    if not function_name then -- multiline support
        local next_line = vim.api.nvim_buf_get_lines(0, vim.fn.line('.') - 1, vim.fn.line('.'), false)[1]
        function_name, args_str = (line .. next_line):match("([%w_%.]+)%s*%((.-)%)")
    end

    if not function_name then
        print("Invalid function call format.")
        return nil, nil
    end

    local args, types = {}, {}
    local pattern = '[^,]+' -- non-quoted arguments

    for arg in args_str:gmatch(pattern) do
        arg = arg:match('^%s*(.-)%s*$') -- trim whitespace
        local name, type_hint

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

---@param args table
function M.generate_params(args)
    local params = {}
    local types = {}

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
            -- Assign the type based on the primitive
            if is_quoted_string then
                types[i] = "string"
            elseif is_number or is_number_string then
                -- Determine if it's an integer or float
                local num = tonumber(arg)
                if num and math.floor(num) == num then
                    types[i] = "int"
                else
                    types[i] = "float"
                end
            end
        else
            param = arg
        end

        table.insert(params, param)
    end

    return params, types
end

-- line number, line contents, arg
---@param current_line number
---@param line string
---@param var_name string
---@return string | nil
local function get_type(current_line, line, var_name)
    local params = {
        textDocument = vim.lsp.util.make_text_document_params(),
        position = {
            line = current_line,
            character = line:find(var_name) - 1
        }
    }

    local result = vim.lsp.buf_request_sync(0, 'textDocument/hover', params, 1000)
    if not result then return nil end

    for _, res in pairs(result) do
        if res.result and res.result.contents and res.result.contents.value then
            return res.result.contents.value:match("Type:%s*`([^`]+)`")
        end
    end

    return nil
end

---@param line string
---@param filetype string
---@return string | nil
function M.extract_return_type(line, filetype)
    if not util.is_type_sensitive(filetype) then return nil end

    local current_line = vim.api.nvim_win_get_cursor(0)[1] - 1
    local type, var_name = line:match(util.var_pattern(filetype))
    if type and type ~= "" then return type end
    if not var_name then return nil end

    -- fallback to lsp if type isn't found
    return get_type(current_line, line, var_name)
end

-- jack frost
---@param arg string
---@param start_line number
---@return number
local function search(arg, start_line)
    -- search backward
    vim.fn.cursor(start_line, 1)
    local backward_result = vim.fn.search("\\<" .. vim.fn.escape(arg, "\\") .. "\\>", "bnW")
    if backward_result ~= 0 then
        return backward_result
    end
    -- search forward
    vim.fn.cursor(start_line, 1)
    return vim.fn.search("\\<" .. vim.fn.escape(arg, "\\") .. "\\>", "nW")
end

---@param args table
---@param filetype string
---@param known_types table
function M.extract_arg_types(args, filetype, known_types)
    if not util.is_type_sensitive(filetype) then return nil end

    local default_type = util.default_arg_type(filetype)
    local bufnr = vim.api.nvim_get_current_buf()
    local current_line = vim.api.nvim_win_get_cursor(0)[1] - 1
    local save_cursor = vim.fn.getcurpos()
    local types = known_types or {}
    local counter = 0
    local max_iterations = 100

    for i, arg in ipairs(args) do
        if types[i] then goto continue end
        local found = false
        local initial_pos = vim.fn.getcurpos() -- initial cursor position at the start of our search
        local search_result = search(arg, current_line-1)

        -- search result for current arg
        while search_result ~= 0 and search_result <= current_line + 1 and counter < max_iterations do
            local line = vim.api.nvim_buf_get_lines(0, search_result - 1, search_result, false)[1]
            local type = get_type(search_result - 1, line, arg)
            if type then
                types[i] = type
                found = true
                break
            end
            -- move cursor to just before the current match to avoid
            -- getting mixed up with repeated matches in different functions
            vim.fn.cursor(search_result - 1, 1)
            local new_pos = vim.fn.getcurpos()
            -- if the cursor returns to the same position (infinite loop) there's no match
            if vim.deep_equal(new_pos, initial_pos) then
                break
            end
            --initial_pos = new_pos
            search_result = search(arg, current_line-1)
            counter = counter + 1
        end

        if not found then
            if default_type then
                types[i] = default_type
            else
                types[i] = vim.fn.input("Type for " .. arg .. ": ")
            end
        end
        ::continue::
    end

    -- Restore cursor position after processing
    vim.fn.setpos('.', save_cursor)

    return #types > 0 and types or nil
end

return M
