local table_builder = require("easytables.tablebuilder")
local math = require("math")

local M = {}

DEFAULT_OPTIONS = {
    title = "Table",
    prompt_title = "Content",
    width = 60,
    height = 30,
    min_value_width = 3,
}

function M:create(options)
    options = options or {}

    self.title = options.title or DEFAULT_OPTIONS.title
    self.prompt_title = options.prompt_title or DEFAULT_OPTIONS.prompt_title
    self.width = options.width or DEFAULT_OPTIONS.width
    self.height = options.height or DEFAULT_OPTIONS.height
    self.min_value_width = options.min_value_width or DEFAULT_OPTIONS.min_value_width

    return self
end

function M:get_x()
    return math.floor((vim.o.columns - self.width) / 2)
end

function M:get_y()
    return math.floor(((vim.o.lines - self.height) / 2) - 1)
end

function M:_open_preview_window()
    self.preview_buffer = vim.api.nvim_create_buf(false, true)
    self.preview_window = vim.api.nvim_open_win(self.preview_buffer, true, {
        relative = "win",
        col = self:get_x(),
        row = self:get_y(),
        width = self.width,
        height = self.height,
        style = "minimal",
        border = "rounded",
        title = self.title,
        title_pos = "center",
    })

    vim.api.nvim_set_option_value("readonly", true, { win = self.preview_window })
    -- Disable default highlight
    vim.api.nvim_set_option_value("winhighlight", "Normal:Normal",
        { win = self.preview_window })
end

function M:_open_prompt_window()
    self.prompt_buffer = vim.api.nvim_create_buf(false, false)
    self.prompt_window = vim.api.nvim_open_win(self.prompt_buffer, true, {
        relative = "win",
        col = self:get_x() - 1,
        row = self:get_y() + self.height + 2,
        width = self.width,
        height = 2,
        style = "minimal",
        border = "rounded",
        title = self.prompt_title,
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

function M:_draw_highlight(table)
    local cell = table:get_highlighted_cell()

    if cell == nil then
        return
    end

    local row = 1 + math.max(0, cell.row - 1) * 2
    local cell_start, cell_end = table:get_cell_positions(cell.col, cell.row, self.min_value_width)

    print(cell_start, cell_end, row)

    vim.api.nvim_buf_set_extmark(
        self.preview_buffer,
        vim.api.nvim_create_namespace("easytables"),
        row - 1,
        cell_start,
        {
            end_col = cell_end * 4,
            hl_group = "NormalFloat",
            hl_mode = "combine",
        }
    )
    vim.api.nvim_buf_set_extmark(
        self.preview_buffer,
        vim.api.nvim_create_namespace("easytables"),
        row + 1,
        cell_start,
        {
            end_col = cell_end * 4,
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
            end_col = cell_end * 2 + 1,
            hl_group = "NormalFloat",
            hl_mode = "combine",
        }
    )
end

function M:draw_table(table)
    local representation = table_builder.draw_representation(table)

    vim.api.nvim_buf_set_lines(self.preview_buffer, 0, -1, false, representation)

    self:_draw_highlight(table)
end

return M
