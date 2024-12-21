local templates = require('config.templates')
local util = require('utility')

local M = {}

function M.prompt_for_types(args)
    local types = {}
    for _, arg in ipairs(args) do
        local input_type = vim.fn.input("Type for " .. arg .. ": ")
        table.insert(types, input_type)
    end
    return types
end

function M.extract_function_info(line)
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

function M.extract_arg_types(args, filetype)
    local requires_types = util.is_type_sensitive(filetype)
    if not requires_types then return nil end
    local default_type = util.default_type(filetype) or false
    local types = {}
    local bufnr = vim.api.nvim_get_current_buf()
    local current_line = vim.api.nvim_win_get_cursor(0)[1] - 1
    -- save the current cursor position(for searching)
    local save_cursor = vim.fn.getcurpos()

    for _, arg in ipairs(args) do
        local found = false
        -- search backwards from current position
        local search_result = vim.fn.search("\\<" .. vim.fn.escape(arg, "\\") .. "\\>", "bnw")

        while search_result ~= 0 and search_result <= current_line + 1 do
            local line = vim.api.nvim_buf_get_lines(0, search_result - 1, search_result, false)[1]
            local var_start = line:match("^%s*[%w_:]+%s+" .. vim.pesc(arg) .. "%s*[=;]")
            if var_start then
                local params = {
                    textDocument = vim.lsp.util.make_text_document_params(),
                    position = {
                        line = search_result - 1,
                        character = line:find(arg) - 1
                    }
                }
                local result = vim.lsp.buf_request_sync(0, 'textDocument/hover', params, 1000)
                local lsp_result = nil
                for _, res in pairs(result or {}) do
                    if res.result then
                        lsp_result = res.result
                        break
                    end
                end

                if lsp_result and lsp_result.contents and lsp_result.contents.value then
                    local content = lsp_result.contents.value
                    local type_match = content:match("Type:%s*`([^`]+)`")
                    if type_match then
                        table.insert(types, type_match)
                        found = true
                        break
                    end
                end
            end
            -- Search for next occurrence backwards
            search_result = vim.fn.search("\\<" .. vim.fn.escape(arg, "\\") .. "\\>", "bnW")
        end

        if not found then
            table.insert(types, default_type)
        end
    end

    -- return cursor position after search is done
    vim.fn.setpos('.', save_cursor)

    return #types > 0 and types or nil
end

-- TODO: add return type to correct spot in template
function M.extract_return_type(line, filetype)
    local requires_types = util.is_type_sensitive(filetype)
    if not requires_types then return nil end
    local default_type = util.default_type(filetype) or false

    local var_name = line:match("^%s*([%w_]+)%s*=%s*[%w_]+%s*%([^)]*%)")
    if not var_name then return default_type end

    local current_line = vim.api.nvim_win_get_cursor(0)[1] - 1
    local params = {
        textDocument = vim.lsp.util.make_text_document_params(),
        position = {
            line = current_line,
            character = line:find(var_name) - 1
        }
    }

    local result = vim.lsp.buf_request_sync(0, 'textDocument/hover', params, 1000)

    local lsp_result = nil
    for _, res in pairs(result or {}) do
        if res.result then
            lsp_result = res.result
            break
        end
    end

    if lsp_result and lsp_result.contents and lsp_result.contents.value then
        local content = lsp_result.contents.value
        local type_match = content:match("Type:%s*`([^`]+)`")
        if type_match then
            return type_match
        end
    end

    return default_type
end

return M
