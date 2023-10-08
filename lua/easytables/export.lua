local o = require("easytables.options")

local M = {}

---comment
---@param content string
---@param width number
---@return string
function M:export_cell(content, width)
    local padding = string.rep(o.options.export.markdown.characters.filler, o.options.export.markdown.padding)

    return
        o.options.export.markdown.characters.vertical
        .. padding
        .. content
        .. string.rep(" ", width - vim.api.nvim_strwidth(content))
        .. padding
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

    return str .. o.options.export.markdown.characters.vertical
end

---comment
---@param widths table
---@return string
function M:create_header_line(widths)
    local str = ""

    -- No idea why, but "ipairs" is required otherwise lua complains
    for _, width in ipairs(widths) do
        str =
            str
            .. o.options.export.markdown.characters.vertical
            .. string.rep(o.options.export.markdown.characters.horizontal, width + o.options.export.markdown.padding * 2)
    end

    return str .. o.options.export.markdown.characters.vertical
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
