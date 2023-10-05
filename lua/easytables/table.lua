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
    col --[[ int ]]
) -- int
    local largest = #self.table[1][col]
    for _, row in ipairs(self.table) do
        if #row[col] > largest then
            largest = #row[col]
        end
    end

    return largest
end

function M:get_largest_length_for_row(
    row --[[ int ]]
) -- int
    local largest = #self.table[row][1]
    for _, col in ipairs(self.table[row]) do
        if #col > largest then
            largest = #col
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
    min_width --[[ int ]]
) -- table
    local widths = {}

    for i = 1, #self.table[1] do
        widths[i] = math.max(min_width, self:get_largest_length_for_column(i))
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

function M:get_cell_positions(col, row, min_value_width)
    local start_position = 1

    for i, cell in ipairs(self.table[row]) do
        if i == col then
            break
        end

        start_position = start_position + #cell + 1
    end

    local end_position = start_position + math.max(min_value_width, #self.table[row][col])

    return start_position, end_position
end

function M:get_highlighted_position()
    if self.highlighted_cell == nil then
        return nil
    end

    local row = self.highlighted_cell.row
    local col = self.highlighted_cell.col

    local cell_start, cell_end = self:get_cell_positions(row, col)

    return cell_start, cell_end
end

return M
