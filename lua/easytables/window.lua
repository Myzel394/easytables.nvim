local table_builder = require("easytables.tablebuilder")
local export = require("easytables.export")
local o = require("easytables.options")
local math = require("math")

local M = {}

local function _get_auto_size(cols, rows)
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

local function get_window_size(cols, rows)
    local option_value = o.options.table.window.size

    if option_value ~= "auto" then
        local width, height = option_value:match("(%d+)x(%d+)")

        return tonumber(width), tonumber(height)
    end

    return _get_auto_size(cols, rows)
end

function M:create(table, options)
    options = options or {}

    self.table = table
    self.previous_window = vim.api.nvim_get_current_win()

    return self
end

function M:get_table_width()
    local widths = self.table:get_widths_for_columns()
    local width = 1

    for _, w in ipairs(widths) do
        width = width + w + 1
    end

    return width
end

function M:get_x()
    local width, _ = self:get_table_width()
    return math.floor((vim.o.columns - width) / 2)
end

function M:get_y()
    local _, height = get_window_size(self.table:cols_amount(), self.table:rows_amount())

    return math.floor(((vim.o.lines - height) / 2) - 1)
end

function M:_set_window_positions()
    local width = self:get_table_width()
    local _, height = get_window_size(self.table:cols_amount(), self.table:rows_amount())

    print("updating", vim.inspect(width), vim.inspect(height))

    vim.api.nvim_win_set_config(self.preview_window, {
        width = width,
        height = height,
        col = self:get_x(),
        row = self:get_y(),
        relative = "editor"
    })
    vim.api.nvim_win_set_config(self.prompt_window, {
        width = width,
        height = 1,
        col = self:get_x(),
        row = self:get_y() + height + 2,
        relative = "editor"
    })
end

function M:_update_active_cell(cell)
    self.table:set_highlighted_cell(cell)

    self:draw_table()

    vim.api.nvim_buf_set_name(self.prompt_buffer, "[Table Cell: " .. cell.row .. "x" .. cell.col .. "]")
end

function M:_open_preview_window()
    self.preview_buffer = vim.api.nvim_create_buf(false, true)
    self.preview_window = vim.api.nvim_open_win(self.preview_buffer, false, {
        style = "minimal",
        border = "rounded",
        title = o.options.table.window.preview_title,
        title_pos = "center",
        focusable = false,
        -- Required for function, will be overwritten by :_set_window_positions`
        relative = "editor",
        row = 0,
        col = 0,
        width = 1,
        height = 1
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
    self.prompt_buffer = vim.api.nvim_create_buf(false, false)
    self.prompt_window = vim.api.nvim_open_win(self.prompt_buffer, true, {
        -- No idea why, but the window is shifted one cell to the right by default
        style = "minimal",
        border = "rounded",
        title = o.options.table.window.prompt_title,
        title_pos = "center",
        -- Required for function, will be overwritten by :_set_window_positions`
        relative = "editor",
        col = 0,
        row = 0,
        width = 1,
        height = 1
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
    self:_set_window_positions()
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
    local widths = self.table:get_widths_for_columns()
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

function M:update_window()
    if o.options.table.window.size == "auto" then
        self:_set_window_positions()
    end
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
                self:update_window()
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
            self:update_window()
            self:_reset_prompt()
        end,
        {}
    )

    vim.api.nvim_buf_create_user_command(
        self.prompt_buffer,
        "JumpToPreviousCell",
        function()
            self.table:move_highlight_to_previous_cell()
            self:update_window()
            self:_reset_prompt()
        end,
        {}
    )

    vim.api.nvim_buf_create_user_command(
        self.prompt_buffer,
        "JumpDown",
        function()
            self.table:move_highlight_down()
            self:update_window()
            self:_reset_prompt()
        end,
        {}
    )

    vim.api.nvim_buf_create_user_command(
        self.prompt_buffer,
        "JumpUp",
        function()
            self.table:move_highlight_up()
            self:update_window()
            self:_reset_prompt()
        end,
        {}
    )

    vim.api.nvim_buf_create_user_command(
        self.prompt_buffer,
        "JumpLeft",
        function()
            self.table:move_highlight_left()
            self:update_window()
            self:_reset_prompt()
        end,
        {}
    )

    vim.api.nvim_buf_create_user_command(
        self.prompt_buffer,
        "JumpRight",
        function()
            self.table:move_highlight_right()
            self:update_window()
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
            self:_update_active_cell(right_cell)
            self:update_window()
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
            self.table:_update_active_cell(left_cell)
            self:update_window()
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
            self.table:_update_active_cell(upper_cell)
            self:update_window()
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
            self.table:_update_active_cell(lower_cell)
            self:update_window()
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
            self:update_window()
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

    o.options.set_mappings(self.prompt_buffer)
end

return M
