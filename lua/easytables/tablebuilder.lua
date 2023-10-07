local o = require("easytables.options")

local function create_horizontal_line(cell_widths, left, middle, right, middle_t)
    local string = ""

    string = string .. left

    for i, width in ipairs(cell_widths) do
        string = string .. string.rep(middle, width)

        if i ~= #cell_widths then
            string = string .. middle_t
        end
    end

    string = string .. right

    return string
end

---Creates a horizontal divider like this:
---`create_horizontal_divider(5, 5, {variant = "top"})`:
---┌─────┬─────┬─────┬─────┬─────┐
---`create_horizontal_divider(5, 5, {variant = "between"})`:
---├─────┼─────┼─────┼─────┼─────┤
---`create_horizontal_divider(5, 5, {variant = "bottom"})`:
---└─────┴─────┴─────┴─────┴─────┘
---@param table table
---@param[opt="between"] variant string Either "top", "between" or "bottom"
---@return string
local function create_horizontal_divider(
    table,
    variant
)
    variant = variant or "between"

    local widths = table:get_widths_for_columns()

    if variant == "top" then
        return create_horizontal_line(
            widths,
            o.options.table.border.top_left,
            o.options.table.border.horizontal,
            o.options.table.border.top_right,
            o.options.table.border.top_t
        )
    elseif variant == "between" then
        return create_horizontal_line(
            widths,
            o.options.table.border.left_t,
            o.options.table.border.horizontal,
            o.options.table.border.right_t,
            o.options.table.border.cross
        )
    elseif variant == "bottom" then
        return create_horizontal_line(
            widths,
            o.options.table.border.bottom_left,
            o.options.table.border.horizontal,
            o.options.table.border.bottom_right,
            o.options.table.border.bottom_t
        )
    elseif variant == "header" then
        return create_horizontal_line(
            widths,
            o.options.table.border.header_left_t,
            o.options.table.border.header_horizontal,
            o.options.table.border.header_right_t,
            o.options.table.border.header_cross
        )
    end

    return ""
end

---Draws a table representation for the preview
---@param table table
---@return table
local function draw_representation(table)
    local representation = {}

    local horizontal_divider = create_horizontal_divider(table, "between")

    representation[#representation + 1] = create_horizontal_divider(table, "top")

    local column_widths = table:get_widths_for_columns()

    for i = 1, table:rows_amount() do
        local line = ""

        for j = 1, table:cols_amount() do
            local length = column_widths[j]
            local cell = table:value_at(i, j)
            local cell_width = vim.api.nvim_strwidth(cell)

            if cell_width < length then
                cell = cell
                    .. string.rep(o.options.table.cell.filler, length - cell_width)
            end

            -- Add left vertical divider
            cell = o.options.table.border.vertical .. cell

            -- Add most right vertical divider
            if j == table:cols_amount() then
                cell = cell .. o.options.table.border.vertical
            end

            line = line .. cell
        end

        representation[#representation + 1] = line

        if i == 1 and table.header_enabled then
            representation[#representation + 1] = create_horizontal_divider(table, "header")
        elseif i ~= table:rows_amount() then
            representation[#representation + 1] = horizontal_divider
        end
    end

    representation[#representation + 1] = create_horizontal_divider(table, "bottom")

    return representation
end

return {
    draw_representation = draw_representation
}
