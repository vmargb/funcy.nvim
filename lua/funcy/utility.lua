local templates = require('config.templates')
local M = {}

function M.is_empty_line(line)
    return line:match("^%s*$")
end

function M.is_type_sensitive(filetype)
    return templates[filetype].type_sensitive or false
end

function M.default_type(filetype)
    return templates[filetype].default_type or false
end

function M.var_pattern(filetype)
    return templates[filetype].var_pattern or false
end

function M.extract_types(args, filetype)
    local requires_types = M.is_type_sensitive(filetype)
    if not requires_types then return nil end

    local default_type = M.default_type(filetype) or false
    local types = {}
    local bufnr = vim.api.nvim_get_current_buf()
    local current_line = vim.api.nvim_win_get_cursor(0)[1] - 1

    -- get all lines up to the current line (to find variable declarations of arguments)
    local lines = vim.api.nvim_buf_get_lines(0, 0, current_line + 1, false)

    for _, arg in ipairs(args) do
        -- search backwards through lines to find the arguments
        local found = false
        for i = #lines, 1, -1 do
            local line = lines[i]
            local var_start = line:match("^%s*[%w_:]+%s+" .. vim.pesc(arg) .. "%s*[=;]")
            if var_start then
                local params = {
                    textDocument = vim.lsp.util.make_text_document_params(),
                    position = {
                        line = i - 1,  -- convert to 0-based line number
                        character = line:find(arg) - 1  -- convert to 0-based column
                    }
                }

                local result = vim.lsp.buf_request_sync(0, 'textDocument/hover', params, 1000)
                -- find the non-empty result
                local lsp_result = nil
                for _, res in pairs(result or {}) do
                    if res.result then
                        lsp_result = res.result
                        break
                    end
                end

                -- extract the type information from lsp results
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
        end

        if not found then
            table.insert(types, default_type)
        end
    end

    return #types > 0 and types or nil
end


function M.format_params(args, types, filetype)
    local requires_types = M.is_type_sensitive(filetype)
    if not requires_types then
        return table.concat(args, ", ")
    end

    local default_type = M.default_type(filetype)

    -- Add types for type-sensitive languages
    local formatted = {}
    for i, arg in ipairs(args) do
        -- TODO: handle cases where types come after the variable
        table.insert(formatted, (types and types[i] or default_type) .. " " .. arg)
    end
    return table.concat(formatted, ", ")
end

-- Check if a line contains a function definition based on templates
function M.is_function_definition(line)
    local filetype = vim.api.nvim_buf_get_option(0, "filetype")
    local template = templates[filetype] or templates.default
    if not template or not template.header then return false end

    -- check if the line starts like a function definition
    local header_format = template.header:gsub("%%s", "([%w_]+)")
    return line:match("^%s*" .. header_format:sub(1, header_format:find("%(") - 1)) ~= nil
end

-- Find the nearest empty line before a given line
function M.find_empty_line_before(line_num)
    for i = line_num - 1, 1, -1 do
        local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
        if M.is_empty_line(line) then
            return i
        end
    end
    return 0 -- default to zero if no empty line is found
end

-- Check if any function definition exists between two lines
function M.has_function_between(start_line, end_line)
    for i = start_line, end_line do
        local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
        if M.is_function_definition(line) then
            return true
        end
    end
    return false
end

return M
