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

    return self
end

function M:insert(row, col, value)
    self.table[row][col] = value
end

function M:value_at(row, col)
    return self.table[row][col]
end

function M:get_largest_length_for_column(
    col, --[[ int ]]
    should_use_strwidth --[[ bool ]]
) -- int
    should_use_strwidth = should_use_strwidth or false

    local largest = #self.table[1][col]
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

function M:get_widths_for_columns(
    min_width --[[ int ]],
    should_use_strwidth --[[ bool ]]
) -- table
    local widths = {}

    for i = 1, #self.table[1] do
        widths[i] = math.max(min_width, self:get_largest_length_for_column(i, should_use_strwidth))
    end

    return widths
end

function M:rows_amount()
    return #self.table
end

function M:cols_amount()
    return #self.table[1]
end

function M:highlight_cell(col, row)
    self.highlighted_cell = { row = row, col = col }
end

function M:get_highlighted_cell()
    return self.highlighted_cell
end

-- Jumps to next cell in row. If there is no next cell, it jumps to the first cell in the next row.
function M:move_highlight_to_next_cell()
    if self.highlighted_cell == nil then
        return
    end

    if self.highlighted_cell.col == self:cols_amount() then
        if self.highlighted_cell.row == self:rows_amount() then
            -- Reset highlight to the first cell
            self.highlighted_cell = {
                col = 1,
                row = 1,
            }
        else
            self.highlighted_cell = {
                col = 1,
                row = self.highlighted_cell.row + 1,
            }
        end
    else
        self.highlighted_cell = {
            col = self.highlighted_cell.col + 1,
            row = self.highlighted_cell.row,
        }
    end
end

-- Jumps to previous cell in row. If there is no previous cell, it jumps to the last cell in the previous row.
function M:move_highlight_to_previous_cell()
    if self.highlighted_cell == nil then
        return
    end

    if self.highlighted_cell.col == 1 then
        if self.highlighted_cell.row == 1 then
            -- Reset highlight to the last cell
            self.highlighted_cell = {
                col = self:cols_amount(),
                row = self:rows_amount(),
            }
        else
            self.highlighted_cell = {
                col = self:cols_amount(),
                row = self.highlighted_cell.row - 1,
            }
        end
    else
        self.highlighted_cell = {
            col = self.highlighted_cell.col - 1,
            row = self.highlighted_cell.row,
        }
    end
end

-- Moves highlight to the right, jumps back to the first cell in the same row if it is already at the rightmost cell.
function M:move_highlight_right()
    if self.highlighted_cell == nil then
        return
    end

    if self.highlighted_cell.col == self:cols_amount() then
        self.highlighted_cell.col = 1
    else
        self.highlighted_cell.col = self.highlighted_cell.col + 1
    end
end

-- Moves highlight to the left, jumps back to the last cell in the same row if it is already at the leftmost cell.
function M:move_highlight_left()
    if self.highlighted_cell == nil then
        return
    end

    if self.highlighted_cell.col == 1 then
        self.highlighted_cell.col = self:cols_amount()
    else
        self.highlighted_cell.col = self.highlighted_cell.col - 1
    end
end

-- Moves highlight to the top, jumps back to the last row if it is already at the topmost row.
function M:move_highlight_up()
    if self.highlighted_cell == nil then
        return
    end

    if self.highlighted_cell.row == 1 then
        self.highlighted_cell.row = self:rows_amount()
    else
        self.highlighted_cell.row = self.highlighted_cell.row - 1
    end
end

-- Moves highlight to the bottom, jumps back to the first row if it is already at the bottommost row.
function M:move_highlight_down()
    if self.highlighted_cell == nil then
        return
    end

    if self.highlighted_cell.row == self:rows_amount() then
        self.highlighted_cell.row = 1
    else
        self.highlighted_cell.row = self.highlighted_cell.row + 1
    end
end

function M:get_cell_positions(col, row, min_value_width)
    local length = #"│"
    local start_position = 0

    for i, cell in ipairs(self.table[row]) do
        if i == col then
            break
        end

        start_position = start_position + math.max(min_value_width, #cell) + length
    end

    local end_position = math.max(length, start_position) + math.max(min_value_width, #self.table[row][col]) + length

    if col ~= 1 then
        -- Add `length again because of the border left and right
        end_position = end_position + length
    end

    return start_position, end_position
end

function M:get_horizontal_border_width(
    col,            -- [[ int ]]
    row,            -- [[ int ]]
    min_value_width -- [[ int ]]
)
    local length = #"─"
    local start_position = 0
    local widths = self:get_widths_for_columns(min_value_width, true)

    for i, _ in ipairs(self.table[1]) do
        if i == col then
            break
        end

        start_position = start_position + math.max(min_value_width, widths[i]) * length

        if row == 1 then
            start_position = start_position + #"┬"
        else
            start_position = start_position + #"┼"
        end
    end

    local end_position = 0

    if col == 1 then
        end_position = #"┬"
    else
        end_position = #"┤"
    end

    end_position = end_position + start_position + math.max(min_value_width, widths[col]) * length

    if row == 1 then
        if col == 1 then
            end_position = end_position + #"┬"
        else
            end_position = end_position + #"┐"
        end
    else
        if col == 1 then
            end_position = end_position + #"├"
        else
            end_position = end_position + #"┤"
        end
    end

    return start_position, end_position
end

return M
