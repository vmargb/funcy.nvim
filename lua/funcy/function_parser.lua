local util = require('utility')

local M = {}

function M.extract_function_info(line)
    local function_name, args_str = line:match("([%w_%.]+)%s*%((.-)%)")
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

function M.extract_return_type(line, filetype)
    if not util.is_type_sensitive(filetype) then return nil end

    local current_line = vim.api.nvim_win_get_cursor(0)[1] - 1
    local type, var_name = line:match(util.var_pattern(filetype))
    if type and type ~= "" then return type end
    if not var_name then return nil end

    -- fallback to lsp if type isn't found
    return get_type(current_line, line, var_name)
end

function M.extract_arg_types(args, filetype)
    if not util.is_type_sensitive(filetype) then return nil end

    local default_type = util.default_arg_type(filetype)
    local bufnr = vim.api.nvim_get_current_buf()
    local current_line = vim.api.nvim_win_get_cursor(0)[1] - 1
    local save_cursor = vim.fn.getcurpos()
    local types = {}

    local counter = 0
    local max_iterations = 1000

    for _, arg in ipairs(args) do
        local found = false
        -- reset to the start line for the search of each arg
        vim.fn.cursor(current_line, 1)
        local initial_pos = vim.fn.getcurpos() -- initial cursor position at the start of our search
        local search_result = vim.fn.search("\\<" .. vim.fn.escape(arg, "\\") .. "\\>", "bnw")

        -- search result for current arg
        while search_result ~= 0 and search_result <= current_line + 1 and counter < max_iterations do
            local line = vim.api.nvim_buf_get_lines(0, search_result - 1, search_result, false)[1]
            local type = get_type(search_result - 1, line, arg)
            if type then
                table.insert(types, type)
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
            search_result = vim.fn.search("\\<" .. vim.fn.escape(arg, "\\") .. "\\>", "bnw")
            counter = counter + 1
        end

        if not found then
            if default_type then
                table.insert(types, default_type)
            else
                table.insert(types, vim.fn.input("Type for " .. arg .. ": "))
            end
        end
    end

    -- Restore cursor position after processing
    vim.fn.setpos('.', save_cursor)

    return #types > 0 and types or nil
end

return M
