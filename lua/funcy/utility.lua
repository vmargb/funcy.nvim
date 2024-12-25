local templates = require('config.templates')
local M = {}

function M.is_empty_line(line)
    return line:match("^%s*$")
end

function M.is_type_sensitive(filetype)
    return templates[filetype].type_sensitive or false
end

function M.template(filetype)
    return templates[filetype] or templates.default
end

function M.default_type(filetype)
    return templates[filetype].default_type or false
end

function M.default_arg_type(filetype)
    return templates[filetype].default_arg_type or false
end

function M.var_pattern(filetype)
    return templates[filetype].var_pattern or false
end

function M.format_params(args, types, filetype, type_pos)
    local requires_types = M.is_type_sensitive(filetype)
    if not requires_types then
        return table.concat(args, ", ")
    end

    local separator = M.template(filetype).type_separator or " " -- Default to `:` for most languages

    local formatted = {}
    for i, arg in ipairs(args) do
        if types and types[i] then
            if type_pos == "start" then
                table.insert(formatted, types[i] .. " " .. arg)
            elseif type_pos == "end" then
                table.insert(formatted, arg .. separator .. types[i])
            end
        else
            -- If no type is provided, just use the argument name
            table.insert(formatted, arg)
        end
    end

    return table.concat(formatted, ", ")
end

function M.format_header(function_name, args, types, return_type, filetype)
    local template = templates[filetype] or templates.default
    local type_pos = template.type_pos

    local formatted_params = M.format_params(args, types, filetype, type_pos)
    local header = ""

    if type_pos == "start" then
        header = string.format(template.header, return_type, function_name, formatted_params)
    elseif type_pos == "end" then
        header = string.format(template.header, function_name, formatted_params, return_type)
    end

    return header
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
