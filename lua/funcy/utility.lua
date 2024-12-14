local templates = require('config.templates')
local M = {}

-- Check if a line is empty
function M.is_empty_line(line)
    return line:match("^%s*$")
end

-- Check if a line contains a function definition based on templates
function M.is_function_definition(line)
    -- Retrieve current filetype
    local filetype = vim.api.nvim_buf_get_option(0, "filetype")
    -- Get the template for the current filetype
    local template = templates[filetype]
    if not template then return false end -- Return false if no template is found

    -- Extract the header format from the template
    local header_format = template.header
    if not header_format then return false end -- Return false if no header format

    -- Use Lua pattern matching to check if the line starts like a function definition
    -- Replace '%s' placeholders with Lua patterns for function names/arguments
    local pattern = header_format:gsub("%%s", "[%w_]+") -- Match valid names for functions or parameters
    return line:match("^%s*" .. pattern:sub(1, pattern:find("%(") - 1)) ~= nil
end

-- Find the nearest empty line before a given line
function M.find_empty_line_before(line_num)
    for i = line_num - 1, 1, -1 do
        local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
        if M.is_empty_line(line) then
            return i
        end
    end
    return nil
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
