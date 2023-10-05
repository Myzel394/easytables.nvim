local M = {};

DEFAULT_DRAW_REPRESENTATION_OPTIONS = {
    min_width = 3,
    filler = " ",
    top_left = "┌",
    top_right = "┐",
    bottom_left = "└",
    bottom_right = "┘",
    horizontal = "─",
    vertical = "│",
    left_t = "├",
    right_t = "┤",
    top_t = "┬",
    bottom_t = "┴",
    cross = "┼"
}

function create_horizontal_line(width, cell_width, left, middle, right, middle_t)
    local string = ""

    for i = 1, width do
        if i == 1 then
            string = string .. left
        elseif i == width then
            string = string .. right
        elseif (i - 1) % (cell_width + 1) == 0 then
            string = string .. middle_t
        else
            string = string .. middle
        end
    end

    return string
end

-- Creates a horizontal divider like this:
-- `create_horizontal_divider(5, 5, {variant = "top"})`:
-- ┌─────┬─────┬─────┬─────┬─────┐
-- `create_horizontal_divider(5, 5, {variant = "between"})`:
-- ├─────┼─────┼─────┼─────┼─────┤
-- `create_horizontal_divider(5, 5, {variant = "bottom"})`:
-- └─────┴─────┴─────┴─────┴─────┘
function create_horizontal_divider(table_width, cell_width, options)
    local options = options or {}
    local top_left = options.top_left or DEFAULT_DRAW_REPRESENTATION_OPTIONS.top_left
    local top_right = options.top_right or DEFAULT_DRAW_REPRESENTATION_OPTIONS.top_right
    local bottom_left = options.bottom_left or DEFAULT_DRAW_REPRESENTATION_OPTIONS.bottom_left
    local bottom_right = options.bottom_right or DEFAULT_DRAW_REPRESENTATION_OPTIONS.bottom_right
    local horizontal = options.horizontal or DEFAULT_DRAW_REPRESENTATION_OPTIONS.horizontal
    local left_t = options.left_t or DEFAULT_DRAW_REPRESENTATION_OPTIONS.left_t
    local right_t = options.right_t or DEFAULT_DRAW_REPRESENTATION_OPTIONS.right_t
    local top_t = options.top_t or DEFAULT_DRAW_REPRESENTATION_OPTIONS.top_t
    local bottom_t = options.bottom_t or DEFAULT_DRAW_REPRESENTATION_OPTIONS.bottom_t
    local cross = options.cross or DEFAULT_DRAW_REPRESENTATION_OPTIONS.cross
    local variant = options.variant or "between"

    local full_width = table_width * cell_width + table_width + 1

    if variant == "top" then
        return create_horizontal_line(full_width, cell_width, top_left, horizontal, top_right, top_t)
    elseif variant == "between" then
        return create_horizontal_line(full_width, cell_width, left_t, horizontal, right_t, cross)
    elseif variant == "bottom" then
        return create_horizontal_line(full_width, cell_width, bottom_left, horizontal, bottom_right, bottom_t)
    end
end

function table.draw_representation(table, options)
    local options = options or {}
    local min_width = options.min_width or DEFAULT_DRAW_REPRESENTATION_OPTIONS.min_width
    local filler = options.filler or DEFAULT_DRAW_REPRESENTATION_OPTIONS.filler
    local vertical = options.vertical or DEFAULT_DRAW_REPRESENTATION_OPTIONS.vertical

    local representation = {}
    local largest_length = table:get_largest_length()
    -- If length is shorter than min_width, then add filler to the end of the string
    local length = largest_length < min_width and min_width or largest_length

    local horizontal_divider = create_horizontal_divider(table:cols_amount(), length, options)

    representation[#representation + 1] = create_horizontal_divider(table:cols_amount(), length, { variant = "top" })

    for i = 1, table:rows_amount() do
        local line = ""
        for j = 1, table:cols_amount() do
            local cell = table:value_at(i, j)
            local cell_width = #cell

            if cell_width < min_width then
                cell = cell .. string.rep(filler, length - cell_width)
            end

            cell = vertical .. cell

            if j == table:cols_amount() then
                cell = cell .. vertical
            end

            line = line .. cell
        end

        representation[#representation + 1] = line

        if i ~= table:rows_amount() then
            representation[#representation + 1] = horizontal_divider
        end
    end

    representation[#representation + 1] = create_horizontal_divider(table:cols_amount(), length, { variant = "bottom" })

    return representation
end

function table.from_representation(representation, options)
    local opts = options or {}

    local table = {}

    for i = 1, #representation do
        local character = representation[i]
    end
end

return table
