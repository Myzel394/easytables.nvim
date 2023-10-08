local table_builder = require("easytables.tablebuilder")
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

-- Just used for autocompletion
local DEFAULT_OPTIONS = {
    on_export = function() end,
}

---Create a new window for the given table
---@param table table
---@param options table
function M:create(table, options)
    options = options or {}

    self.table = table
    self.previous_window = vim.api.nvim_get_current_win()

    self.on_export = options.on_export or DEFAULT_OPTIONS.on_export

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

    width = math.max(20, width)
    height = math.max(10, height)

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
    self:_reset_prompt()
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
    -- Wrap all in pcall to prevent errors when closing windows
    pcall(function()
        vim.api.nvim_win_close(self.preview_window, true)
    end)
    pcall(function()
        vim.api.nvim_win_close(self.prompt_window, true)
    end)
    pcall(function()
        vim.api.nvim_set_current_win(self.previous_window)
    end)

    pcall(function()
        vim.api.nvim_buf_delete(self.preview_buffer, { force = true })
    end)
    pcall(function()
        vim.api.nvim_buf_delete(self.prompt_buffer, { force = true })
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

    local cmds = {
    }

    for cmd, func in pairs(cmds) do
        vim.api.nvim_buf_create_user_command(
            self.prompt_buffer,
            cmd,
            function()
                func()
                self:update_window()
                self:_reset_prompt()
            end,
            {}
        )
    end

    local cmds = {
        JumpToNextCell = function()
            local cell = self.table:get_highlighted_cell()

            if cell.col == self.table:cols_amount() then
                if cell.row == self.table:rows_amount() then
                    -- Reset highlight to the first cell
                    return {
                        col = 1,
                        row = 1,
                    }
                else
                    return {
                        col = 1,
                        row = cell.row + 1,
                    }
                end
            end

            return {
                col = cell.col + 1,
                row = cell.row
            }
        end,
        JumpToPreviousCell = function()
            local cell = self.table:get_highlighted_cell()

            if cell.col == 1 then
                if cell.row == 1 then
                    -- Reset highlight to the last cell
                    return {
                        col = self.table:cols_amount(),
                        row = self.table:rows_amount(),
                    }
                else
                    return {
                        col = self.table:cols_amount(),
                        row = cell.row - 1,
                    }
                end
            end

            return {
                col = cell.col - 1,
                row = cell.row,
            }
        end,

        JumpDown = function()
            local cell = self.table:get_highlighted_cell()

            return {
                row = cell.row == self.table:rows_amount() and 1 or cell.row + 1,
                col = cell.col,
            }
        end,
        JumpUp = function()
            local cell = self.table:get_highlighted_cell()

            return {
                row = cell.row == 1 and self.table:rows_amount() or cell.row - 1,
                col = cell.col,
            }
        end,
        JumpLeft = function()
            local cell = self.table:get_highlighted_cell()

            return {
                row = cell.row,
                col = cell.col == 1 and self.table:cols_amount() or cell.col - 1,
            }
        end,
        JumpRight = function()
            local cell = self.table:get_highlighted_cell()

            return {
                row = cell.row,
                col = cell.col == self.table:cols_amount() and 1 or cell.col + 1,
            }
        end,

        DeleteColumn = function() self.table:delete_col(self.table:get_highlighted_cell().col) end,
        DeleteRow = function() self.table:delete_row(self.table:get_highlighted_cell().row) end,

        InsertColumnRight = function()
            self.table:insert_col(self.table:get_highlighted_cell().col)
            return {
                row = self.table:get_highlighted_cell().row,
                col = self.table:get_highlighted_cell().col + 1,
            }
        end,
        InsertColumnLeft = function()
            self.table:insert_col(self.table:get_highlighted_cell().col - 1)
            return {
                row = self.table:get_highlighted_cell().row,
                col = self.table:get_highlighted_cell().col,
            }
        end,
        InsertRowBelow = function()
            self.table:insert_row(self.table:get_highlighted_cell().row)
            return {
                row = self.table:get_highlighted_cell().row + 1,
                col = self.table:get_highlighted_cell().col,
            }
        end,
        InsertRowAbove = function()
            self.table:insert_row(self.table:get_highlighted_cell().row - 1)
            return {
                row = self.table:get_highlighted_cell().row,
                col = self.table:get_highlighted_cell().col,
            }
        end,

        SwapWithRightCell = function()
            local cell = self.table:get_highlighted_cell()

            local target = {
                row = cell.row,
                col = cell.col == self.table:cols_amount() and 1 or cell.col + 1,
            }
            self.table:swap_current_with_target(target)
            return target
        end,
        SwapWithLeftCell = function()
            local cell = self.table:get_highlighted_cell()

            local target = {
                row = cell.row,
                col = cell.col == 1 and self.table:cols_amount() or cell.col - 1,
            }
            self.table:swap_current_with_target(target)
            return target
        end,
        SwapWithUpperCell = function()
            local cell = self.table:get_highlighted_cell()

            local target = {
                row = cell.row == 1 and self.table:rows_amount() or cell.row - 1,
                col = cell.col,
            }
            self.table:swap_current_with_target(target)
            return target
        end,
        SwapWithLowerCell = function()
            local cell = self.table:get_highlighted_cell()

            local target = {
                row = cell.row == self.table:rows_amount() and 1 or cell.row + 1,
                col = cell.col,
            }
            self.table:swap_current_with_target(target)
            return target
        end,

        SwapWithLeftColumn = function()
            local cell = self.table:get_highlighted_cell()

            self.table:swap_cols(
                cell.col,
                cell.col == 1 and self.table:cols_amount() or cell.col - 1
            )

            return {
                row = cell.row,
                col = cell.col == 1 and self.table:cols_amount() or cell.col - 1,
            }
        end,
        SwapWithRightColumn = function()
            local cell = self.table:get_highlighted_cell()

            self.table:swap_cols(
                cell.col,
                cell.col == self.table:cols_amount() and 1 or cell.col + 1
            )

            return {
                row = cell.row,
                col = cell.col == self.table:cols_amount() and 1 or cell.col + 1,
            }
        end,
        SwapWithUpperRow = function()
            local cell = self.table:get_highlighted_cell()

            self.table:swap_rows(
                cell.row,
                cell.row == 1 and self.table:rows_amount() or cell.row - 1
            )

            return {
                row = cell.row == 1 and self.table:rows_amount() or cell.row - 1,
                col = cell.col,
            }
        end,
        SwapWithLowerRow = function()
            local cell = self.table:get_highlighted_cell()

            self.table:swap_rows(
                cell.row,
                cell.row == self.table:rows_amount() and 1 or cell.row + 1
            )

            return {
                row = cell.row == self.table:rows_amount() and 1 or cell.row + 1,
                col = cell.col,
            }
        end,
    }

    for cmd, func in pairs(cmds) do
        vim.api.nvim_buf_create_user_command(
            self.prompt_buffer,
            cmd,
            function()
                local new_cell = func()

                if new_cell ~= nil then
                    self:_update_active_cell(new_cell)
                end

                self:update_window()
                self:_reset_prompt()
            end,
            {}
        )
    end

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
            self:close()

            self.on_export()
        end,
        {}
    )

    o.options.set_mappings(self.prompt_buffer)
end

return M
