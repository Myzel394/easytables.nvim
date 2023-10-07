local table_builder = require("easytables.tablebuilder")
local export = require("easytables.export")
local o = require("easytables.options")
local math = require("math")

local M = {}

local function get_window_size(cols, rows)
    local option_value = o.options.table.window.size

    if option_value ~= "auto" then
        local width, height = option_value:match("(%d+)x(%d+)")

        return tonumber(width), tonumber(height)
    end

    local width =
    -- Border widths
        (1 + cols)
        -- Cell widths
        + (cols * o.options.table.cell.min_width)
    local height =
        (1 + rows)
        + rows

    return width, height
end

function M:create(table, options)
    options = options or {}

    self.table = table
    self.previous_window = vim.api.nvim_get_current_win()

    return self
end

function M:get_x()
    local width, _ = get_window_size(self.table:cols_amount(), self.table:rows_amount())
    local diff = vim.o.columns - vim.api.nvim_win_get_width(self.previous_window)
    local pos = vim.o.columns - width - diff

    return math.floor(pos / 2)
end

function M:get_y()
    local _, height = get_window_size(self.table:cols_amount(), self.table:rows_amount())

    return math.floor(((vim.o.lines - height) / 2) - 1)
end

function M:_open_preview_window()
    local width, height = get_window_size(self.table:cols_amount(), self.table:rows_amount())

    self.preview_buffer = vim.api.nvim_create_buf(false, true)
    self.preview_window = vim.api.nvim_open_win(self.preview_buffer, false, {
        relative = "win",
        col = self:get_x(),
        row = self:get_y(),
        width = width,
        height = height,
        style = "minimal",
        border = "rounded",
        title = o.options.table.window.preview_title,
        title_pos = "center",
        focusable = false,
    })

    -- Disable default highlight
    vim.api.nvim_set_option_value(
        "winhighlight",
        "Normal:Normal",
        { win = self.preview_window }
    )
    vim.api.nvim_set_option_value(
        "wrap",
        false,
        { win = self.preview_window }
    )
end

function M:_open_prompt_window()
    local width, preview_height = get_window_size(self.table:cols_amount(), self.table:rows_amount())

    self.prompt_buffer = vim.api.nvim_create_buf(false, false)
    self.prompt_window = vim.api.nvim_open_win(self.prompt_buffer, true, {
        relative = "win",
        -- No idea why, but the window is shifted one cell to the right by default
        col = self:get_x(),
        row = self:get_y() + preview_height + 2,
        width = width,
        height = 2,
        style = "minimal",
        border = "rounded",
        title = o.options.table.window.prompt_title,
        title_pos = "center",
    })

    vim.api.nvim_set_option_value('winhighlight', "Normal:Normal", { win = self.prompt_window })
end

function M:show()
    -- Don't open window again if it's already opened
    if self.preview_window then
        return
    end

    self:_open_preview_window()
    self:_open_prompt_window()
end

function M:_reset_prompt()
    local highlighted_cell = self.table:get_highlighted_cell()
    local newtext = self.table:value_at(highlighted_cell.row, highlighted_cell.col)
    local newlines = { newtext }

    vim.api.nvim_buf_set_lines(self.prompt_buffer, 0, -1, false, newlines)
end

function M:_draw_highlight()
    local cell = self.table:get_highlighted_cell()

    if cell == nil then
        return
    end

    local row = 1 + math.max(0, cell.row - 1) * 2
    local widths = self.table:get_widths_for_columns(self.min_value_width)
    local cell_start, cell_end = self.table:get_cell_positions(cell.col, cell.row, widths)
    local border_start, border_end = self.table:get_horizontal_border_width(cell.col, cell.row, self.min_value_width)

    vim.api.nvim_buf_set_extmark(
        self.preview_buffer,
        vim.api.nvim_create_namespace("easytables"),
        row - 1,
        border_start,
        {
            end_col = border_end,
            hl_group = "NormalFloat",
            hl_mode = "combine",
        }
    )
    vim.api.nvim_buf_set_extmark(
        self.preview_buffer,
        vim.api.nvim_create_namespace("easytables"),
        row + 1,
        border_start,
        {
            end_col = border_end,
            hl_group = "NormalFloat",
            hl_mode = "combine",
        }
    )
    vim.api.nvim_buf_set_extmark(
        self.preview_buffer,
        vim.api.nvim_create_namespace("easytables"),
        row,
        cell_start,
        {
            end_col = cell_end,
            hl_group = "NormalFloat",
            hl_mode = "combine",
        }
    )
end

function M:draw_table()
    local representation = table_builder.draw_representation(self.table)

    vim.api.nvim_buf_set_lines(self.preview_buffer, 0, -1, false, representation)

    self:_draw_highlight()
end

function M:close()
    vim.api.nvim_win_close(self.preview_window, true)
    vim.api.nvim_win_close(self.prompt_window, true)

    pcall(function()
        vim.api.nvim_set_current_win(self.previous_window)
    end)

    self.preview_window = nil
    self.prompt_window = nil
    self.preview_buffer = nil
    self.prompt_buffer = nil
    self.previous_window = nil
end

function M:register_listeners()
    vim.api.nvim_buf_attach(self.prompt_buffer, false, {
        on_lines = function(_, handle)
            local lines = vim.api.nvim_buf_get_lines(handle, 0, -1, false)

            vim.schedule(function()
                local selected_cell = self.table:get_highlighted_cell()

                self.table:insert(selected_cell.col, selected_cell.row, lines[1])
                self:draw_table()
            end)
        end,
    })

    vim.api.nvim_create_autocmd(
        { "QuitPre" },
        {
            buffer = self.prompt_buffer,
            callback = function()
                self:close()
            end
        }
    )

    vim.api.nvim_buf_create_user_command(
        self.prompt_buffer,
        "JumpToNextCell",
        function()
            self.table:move_highlight_to_next_cell()
            self:draw_table()
            self:_reset_prompt()
        end,
        {}
    )

    vim.api.nvim_buf_create_user_command(
        self.prompt_buffer,
        "JumpToPreviousCell",
        function()
            self.table:move_highlight_to_previous_cell()
            self:draw_table()
            self:_reset_prompt()
        end,
        {}
    )

    vim.api.nvim_buf_create_user_command(
        self.prompt_buffer,
        "JumpDown",
        function()
            self.table:move_highlight_down()
            self:draw_table()
            self:_reset_prompt()
        end,
        {}
    )

    vim.api.nvim_buf_create_user_command(
        self.prompt_buffer,
        "JumpUp",
        function()
            self.table:move_highlight_up()
            self:draw_table()
            self:_reset_prompt()
        end,
        {}
    )

    vim.api.nvim_buf_create_user_command(
        self.prompt_buffer,
        "JumpLeft",
        function()
            self.table:move_highlight_left()
            self:draw_table()
            self:_reset_prompt()
        end,
        {}
    )

    vim.api.nvim_buf_create_user_command(
        self.prompt_buffer,
        "JumpRight",
        function()
            self.table:move_highlight_right()
            self:draw_table()
            self:_reset_prompt()
        end,
        {}
    )

    vim.api.nvim_buf_create_user_command(
        self.prompt_buffer,
        "SwapWithRightCell",
        function()
            local current_cell = self.table:get_highlighted_cell()

            local right_cell = {
                row = current_cell.row,
                col = current_cell.col == self.table:cols_amount() and 1 or current_cell.col + 1,
            }
            self.table:swap_contents(current_cell, right_cell)
            self.table:set_highlighted_cell(right_cell)
            self:draw_table()
            self:_reset_prompt()
        end,
        {}
    )

    vim.api.nvim_buf_create_user_command(
        self.prompt_buffer,
        "SwapWithLeftCell",
        function()
            local current_cell = self.table:get_highlighted_cell()

            local left_cell = {
                row = current_cell.row,
                col = current_cell.col == 1 and self.table:cols_amount() or current_cell.col - 1,
            }
            self.table:swap_contents(current_cell, left_cell)
            self.table:set_highlighted_cell(left_cell)
            self:draw_table()
            self:_reset_prompt()
        end,
        {}
    )

    vim.api.nvim_buf_create_user_command(
        self.prompt_buffer,
        "SwapWithUpperCell",
        function()
            local current_cell = self.table:get_highlighted_cell()

            local upper_cell = {
                row = current_cell.row == 1 and self.table:rows_amount() or current_cell.row - 1,
                col = current_cell.col,
            }
            self.table:swap_contents(current_cell, upper_cell)
            self.table:set_highlighted_cell(upper_cell)
            self:draw_table()
            self:_reset_prompt()
        end,
        {}
    )

    vim.api.nvim_buf_create_user_command(
        self.prompt_buffer,
        "SwapWithLowerCell",
        function()
            local current_cell = self.table:get_highlighted_cell()

            local lower_cell = {
                row = current_cell.row == self.table:rows_amount() and 1 or current_cell.row + 1,
                col = current_cell.col,
            }
            self.table:swap_contents(current_cell, lower_cell)
            self.table:set_highlighted_cell(lower_cell)
            self:draw_table()
            self:_reset_prompt()
        end,
        {}
    )

    vim.api.nvim_buf_create_user_command(
        self.prompt_buffer,
        "ToggleHeader",
        function()
            self.table:toggle_header()
            self:draw_table()
        end,
        {}
    )

    vim.api.nvim_buf_create_user_command(
        self.prompt_buffer,
        "ExportTable",
        function()
            local markdown_table = export:export_table(self.table)

            self:close()

            vim.schedule(function()
                local cursor = vim.api.nvim_win_get_cursor(0)

                vim.api.nvim_buf_set_text(
                    0,
                    cursor[1] - 1,
                    cursor[2],
                    cursor[1] - 1,
                    cursor[2],
                    markdown_table
                )
            end)
        end,
        {}
    )
end

return M
