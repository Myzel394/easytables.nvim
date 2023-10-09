local o = require("easytables.options")

local M = {};

function M:create(cols, rows)
    local table = {}
    for i = 1, rows do
        table[i] = {}
        for j = 1, cols do
            table[i][j] = ""
        end
    end

    self.table = table
    self.highlighted_cell = {
        col = 1,
        row = 1,
    }

    if rows > 1 then
        self.header_enabled = o.options.table.header_enabled_by_default
    else
        self.header_enabled = false
    end

    return self
end

function M:import(table)
    self.table = table
    self.highlighted_cell = {
        col = 1,
        row = 1,
    }

    if #table > 1 then
        self.header_enabled = o.options.table.header_enabled_by_default
    else
        self.header_enabled = false
    end

    return self
end

function M:insert(col, row, value)
    self.table[row][col] = value
end

function M:value_at(row, col)
    return self.table[row][col]
end

function M:toggle_header()
    if #self.table == 1 then
        error("Cannot toggle header if table has only one row")
        return
    end

    self.header_enabled = not self.header_enabled
end

function M:get_largest_length_for_column(
    col, --[[ int ]]
    should_use_strwidth --[[ bool ]]
) -- int
    should_use_strwidth = should_use_strwidth or false

    local largest = 0
    for _, row in ipairs(self.table) do
        if #row[col] > largest then
            largest = should_use_strwidth and vim.api.nvim_strwidth(row[col]) or #row[col]
        end
    end

    return largest
end

function M:get_largest_length()
    local largest = #self.table[1][1]
    for _, row in ipairs(self.table) do
        for _, col in ipairs(row) do
            if #col > largest then
                largest = #col
            end
        end
    end

    return largest
end

---
---@param should_use_strwidth boolean
---@return table
function M:get_widths_for_columns(should_use_strwidth)
    local widths = {}

    for i = 1, #self.table[1] do
        widths[i] = math.max(
            o.options.table.cell.min_width,
            self:get_largest_length_for_column(i, should_use_strwidth)
        )
    end

    return widths
end

function M:rows_amount()
    return #self.table
end

function M:cols_amount()
    return #self.table[1]
end

function M:set_highlighted_cell(cell)
    self.highlighted_cell = cell
end

function M:get_highlighted_cell()
    return self.highlighted_cell
end

function M:get_cell_positions(col, row, widths)
    local length = #o.options.table.border.vertical
    local start_position = 0

    for i, _ in ipairs(self.table[row]) do
        if i == col then
            break
        end

        start_position = start_position + widths[i] + length
    end

    local end_position = math.max(length, start_position) + widths[col] + length

    if col ~= 1 then
        -- Add `length again because of the border left and right
        end_position = end_position + length
    end

    return start_position, end_position
end

---
---@param col boolean
---@param row boolean
---@return number, number
function M:get_horizontal_border_width(col, row)
    local length = #o.options.table.border.horizontal
    local start_position = 0
    local widths = self:get_widths_for_columns(true)

    for i, _ in ipairs(self.table[1]) do
        if i == col then
            break
        end

        start_position =
            start_position
            + math.max(o.options.table.cell.min_width, widths[i]) * length

        if row == 1 then
            start_position = start_position + #o.options.table.border.top_t
        else
            start_position = start_position + #o.options.table.border.cross
        end
    end

    local end_position = 0

    if col == 1 then
        end_position = #o.options.table.border.top_t
    else
        end_position = #o.options.table.border.right_t
    end

    end_position =
        end_position
        + start_position
        + math.max(o.options.table.cell.min_width, widths[col]) * length

    if row == 1 then
        if col == 1 then
            end_position = end_position + #o.options.table.border.top_t
        else
            end_position = end_position + #o.options.table.border.top_right
        end
    else
        if col == 1 then
            end_position = end_position + #o.options.table.border.left_t
        else
            end_position = end_position + #o.options.table.border.right_t
        end
    end

    return start_position, end_position
end

function M:swap_contents(first, second)
    local first_value = self:value_at(first.row, first.col)
    local second_value = self:value_at(second.row, second.col)

    self:insert(first.col, first.row, second_value)
    self:insert(second.col, second.row, first_value)
end

function M:swap_current_with_target(target)
    self:swap_contents(self:get_highlighted_cell(), target)
end

---Clamps the highlighted cell to the table
function M:_clamp_highlight_cell()
    self.highlighted_cell = {
        col = math.max(
            1,
            math.min(self.highlighted_cell.col, self:cols_amount())
        ),
        row = math.max(
            1,
            math.min(self.highlighted_cell.row, self:rows_amount())
        ),
    }
end

---Inserts a new empty row at the given index (zero based)
---Example: 0 would insert a new row at the top of the table
---Example: 1 would insert a new row at the second position of the table
---Example: length of table would insert a new row at the bottom of the table
function M:insert_row(index)
    local row = {}
    for i = 1, self:cols_amount() do
        row[i] = ""
    end

    table.insert(self.table, index + 1, row)
end

---Inserts a new empty column at the given index (zero based)
function M:insert_col(index)
    for _, row in ipairs(self.table) do
        table.insert(row, index + 1, "")
    end
end

function M:delete_col(col)
    if (#self.table[1] == 1) then
        error("Cannot delete last column")
        return
    end

    for _, row in ipairs(self.table) do
        table.remove(row, col)
    end

    self:_clamp_highlight_cell()
end

function M:delete_row(row)
    if (#self.table == 1) then
        error("Cannot delete last row")
        return
    end

    table.remove(self.table, row)

    self.header_enabled = #self.table > 1
    self:_clamp_highlight_cell()
end

function M:swap_cols(first, second)
    for _, row in ipairs(self.table) do
        local first_value = row[first]
        local second_value = row[second]

        row[first] = second_value
        row[second] = first_value
    end
end

function M:swap_rows(first, second)
    local first_row = self.table[first]
    local second_row = self.table[second]

    self.table[first] = second_row
    self.table[second] = first_row
end

return M
