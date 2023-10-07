-- All available options are listed below. The default values are shown.
local DEFAULT = {
    table = {
        window = {
            preview_title = "Table Preview",
            prompt_title = "Cell content",
            -- Either "auto" to automatically size the window, or a string
            -- in the format of "<width>x<height>" (e.g. "20x10")
            size = "auto"
        },
        cell = {
            -- Min width of a cell (excluding padding)
            min_width = 3,
            -- Filler character for empty cells
            filler = " ",
            align = "left",
            -- Padding around the cell content, applied BOTH left AND right
            -- E.g: padding = 1, content = "foo" -> " foo "
            padding = 1,
        },
        -- Characters used to draw the table
        -- Do not worry about multibyte characters, they are handled correctly
        border = {
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
            cross = "┼",
            header_left_t = "╞",
            header_right_t = "╡",
            header_bottom_t = "╧",
            header_cross = "╪",
            header_horizontal = "═",
        }
    },
}

-- You can ignore everything below this line

local options = {}

local function tableMerge(t1, t2)
    for k, v in pairs(t2) do
        if type(v) == "table" then
            if type(t1[k] or false) == "table" then
                tableMerge(t1[k] or {}, t2[k] or {})
            else
                t1[k] = v
            end
        else
            t1[k] = v
        end
    end
    return t1
end

local function merge_options(user_options)
    options = tableMerge(DEFAULT, user_options)
end

return {
    merge_options = merge_options,
    options = options
}
