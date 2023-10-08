local o = require("easytables.options")

---Finds the start of the table. Currently only returns 0 as characters before the table are not supported.
local function find_col_start(buffer, row)
    local result = vim.api.nvim_buf_get_lines(buffer, row, row + 1, false)

    if #result == 0 then
        return nil
    end

    local first_char = string.sub(result[1], 1, 1)

    if first_char == o.options.export.markdown.characters.vertical then
        return 0
    end
    return nil
end

local function find_row_start(buffer)
    local position = vim.api.nvim_win_get_cursor(0)

    local current_line = position[1] - 1
    while true do
        if find_col_start(buffer, current_line) == nil then
            return current_line + 1
        elseif current_line == 1 then
            return 0
        end

        current_line = current_line - 1
    end
end

---Only call this after `find_row_start` was successful.
---@param buffer number
---@param row_start number
---@return number?
local function find_row_end(
    buffer,
    row_start
)
    local current = row_start

    while find_col_start(buffer, current) ~= nil do
        current = current + 1
    end

    return current
end

local function find_col_end(
    buffer,
    row_start
)
    -- Return last position of the row, as characters after tables are not supported.
    return #vim.api.nvim_buf_get_text(buffer, row_start, -1, row_start, -1, {})
end

local function _is_header_line(line, widths)
    -- Check for each cell whether it only contains horizontal chars and is the same length as widths
    local previous_width = 0
    local cell_index = 1

    for i = 2, #line, 1 do
        local char = string.sub(line, i, i)

        if char == o.options.export.markdown.characters.vertical then
            local expected_width = widths[cell_index]

            -- Allow also - 2 width as some formatters apply spaces around the horizontal lines
            if previous_width ~= expected_width and previous_width ~= expected_width - 2 then
                return false
            end

            previous_width = 0
            cell_index = cell_index + 1
        elseif char ~= o.options.export.markdown.characters.horizontal and char ~= o.options.export.markdown.characters.filler then
            return false
        else
            previous_width = previous_width + 1
        end
    end

    return true
end

---Calculates the width of each column in the given line.
---@param line string
---@return table
local function _get_widths(line)
    local widths = {}

    local current = 0
    -- Skip first as it's a vertical line
    for i = 2, #line do
        local char = string.sub(line, i, i)

        if char == o.options.export.markdown.characters.vertical then
            widths[#widths + 1] = current
            current = 0
        else
            current = current + 1
        end
    end

    return widths
end

---Extracts the raw table string from the given buffer.
---@param buffer number
---@param row_start number
---@param row_end number
---@return table of strings
local function extract_table(
    buffer,
    row_start,
    row_end
)
    local lines = vim.api.nvim_buf_get_lines(buffer, row_start, row_end, false)

    local table = {}

    local widths = _get_widths(lines[1])

    for i, line in ipairs(lines) do
        local is_header = i == 2 and _is_header_line(line, widths)

        if not is_header then
            table[#table + 1] = {}

            for content in string.gmatch(line, "[^" .. o.options.export.markdown.characters.vertical .. "]+") do
                table[#table][#table[#table] + 1] = string.gsub(content, '^%s*(.-)%s*$', '%1')
            end
        end
    end

    return table
end


return {
    find_col_start = find_col_start,
    find_row_start = find_row_start,
    find_row_end = find_row_end,
    find_col_end = find_col_end,
    extract_table = extract_table
}
