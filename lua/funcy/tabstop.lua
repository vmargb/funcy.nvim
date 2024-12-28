local M = {}

local placeholders = {
    positions = {},
    index = 0,
}

function M.set_placeholders(placeholder_list)
    placeholders.positions = placeholder_list
    placeholders.index = 0
end

-- jump to the next placeholder
function M.jump_to_next()
    if not placeholders.positions or #placeholders.positions == 0 then
        print("No placeholders to jump to.")
        return
    end

    local buf = vim.api.nvim_get_current_buf()
    -- wrap around
    local current_index = placeholders.index or 0
    current_index = (current_index % #placeholders.positions) + 1
    placeholders.index = current_index

    local pos = placeholders.positions[current_index]
    local line = pos.line - 1
    local col = pos.col

    -- move cursor to the placeholder
    vim.api.nvim_win_set_cursor(0, { line + 1, col })
    vim.cmd("startinsert")
end

return M
