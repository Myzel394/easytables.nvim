local M = {}

---comment
---@param content string
---@param width number
---@return table
function M:export_cell(content, width)
    return "| " .. content .. string.rep(" ", width - #content) .. " "
end

---Exports a line to a string
---@param line table Cells divided into columns
---@param widths table Width of each column
---@return string
function M:export_line(line, widths)
    local str = ""

    for i, cell in ipairs(line) do
        local width = widths[i]

        str = str .. self:export_cell(cell, width)
    end

    return str .. "|"
end

---comment
---@param widths table
---@return string
function M:create_header_line(widths)
    local str = ""

    -- No idea why, but "ipairs" is required otherwise lua complains
    for _, width in ipairs(widths) do
        str = str .. "|" .. string.rep("-", width + 2)
    end

    return str .. "|"
end

---comment
---@return table
function M:export_table(
    table
)
    local representation = {}

    local widths = table:get_widths_for_columns(1)

    for i, line in ipairs(table.table) do
        representation[#representation + 1] = self:export_line(line, widths)

        if i == 1 and table.header_enabled then
            representation[#representation + 1] = self:create_header_line(widths)
        end
    end

    return representation
end

return M
