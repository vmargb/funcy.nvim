local M = {}

---@param params table
---@param types table
---@param template table
---@param placeholders table
---@param function_name string
---@param insert_line_num number
---@return string
function M.format_params_and_placeholders(params, types, template, placeholders, function_name, insert_line_num)
    local formatted_params = {}
    local col = #function_name + 2 -- Start after "function_name("

    for i, param in ipairs(params) do
        local formatted_param
        if template.type_sensitive then
            if types[i] then
                formatted_param = string.format("%s %s", types[i], param)
            else
                table.insert(placeholders, { row = insert_line_num, col = col })
            end
        else
            formatted_param = param
        end

        table.insert(formatted_params, formatted_param)
        col = col + #formatted_param + 2 -- Move to the next param (", " adds 2 chars)
    end

    return table.concat(formatted_params, ", ")
end

---@param function_name string
---@param formatted_params string
---@param return_type string
---@param template table
---@return string
function M.generate_function_header(function_name, formatted_params, return_type, template)
    if template.type_sensitive then
        return string.format(template.header, return_type, function_name, formatted_params)
    else
        return string.format(template.header, function_name, formatted_params)
    end
end

---@param params table
---@param template table
---@return string
function M.generate_function_body(params, template)
    local indent = string.rep(" ", vim.api.nvim_buf_get_option(0, "shiftwidth"))
    local body = ""
    for _, param in ipairs(params) do
        body = body .. string.format(template.body, indent, param, param)
    end
    return body
end

---@param function_name string
---@param params table
---@param types table
---@param return_type string
---@param template table
---@param insert_line_num number
---@return string, table
function M.format_function(function_name, params, types, return_type, template, insert_line_num)
    local placeholders = {}
    local formatted_params = M.format_params_and_placeholders(params, types, template, placeholders, function_name, insert_line_num)

    -- Generate header
    local header = M.generate_function_header(function_name, formatted_params, return_type, template)
    -- Generate body
    local body = M.generate_function_body(params, template)

    -- Combine header, body, and footer
    local footer = template.footer or ""
    local function_def = header .. body .. footer

    return function_def, placeholders
end

return M
