local Input = require("nui.input")
local event = require("nui.utils.autocmd").event
local table = require("easytables.table")
local table_builder = require("easytables.tablebuilder")

local function create_win()
end

local function show_table_builder(rows, cols)
    create_win()
end

local function get_size()
    local dialog_input = Input({
        position = "50%",
        size = {
            width = 60,
        },
        border = {
            style = "single",
            text = {
                top = "[What's the size of your table?]",
                top_align = "center",
            },
        },
        win_options = {
            winhighlight = "Normal:Normal,FloatBorder:Normal",
        },
    }, {
        prompt = "> ",
        default_value = "3x3",
        on_submit = function(value)
            _, _, rows, create_singular, cols = string.find(value, "(%d+)(x?)(%d*)")

            if cols == "" then
                if create_singular == "x" then
                    cols = "1"
                else
                    cols = rows
                end
            end

            rows = tonumber(rows)
            cols = tonumber(cols)

            show_table_builder(rows, cols)
        end,
    })

    dialog_input:mount()

    dialog_input:on(event.BufLeave, function()
        dialog_input:unmount()
    end)
end

local function a()
    local own_table = table:create(6, 3)
    local buffer = vim.api.nvim_create_buf(false, true)

    -- Center
    local width = 40
    local height = 20
    local x = math.floor((vim.o.columns - width) / 2)
    local win = vim.api.nvim_open_win(buffer, true, {
        relative = "win",
        row = math.floor(((vim.o.lines - height) / 2) - 1),
        col = x,
        width = width,
        height = height,
        style = "minimal",
        border = "rounded",
        title = "",
        title_pos = "center",
    })

    vim.api.nvim_set_option_value('winhl', 'Normal:MyHighlight', { win = win })


    local new_win = vim.api.nvim_open_win(buffer, true, {
        relative = "win",
        row = math.floor(((vim.o.lines - height) / 2) - 1) + height + 1,
        col = x - 1,
        width = width,
        height = 2,
        style = "minimal",
        border = "rounded",
        title = "",
        title_pos = "center",
    })

    local representation = table_builder.draw_representation(own_table)

    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, representation)

    vim.api.nvim_buf_attach(buffer, false, {
        on_lines = function(_, handle, _, firstline, lastline, new_lastline)
            local new_text = vim.api.nvim_buf_get_lines(handle, firstline, new_lastline, true)

            print(new_text[1])
        end,
    })
end

return {
    a = a,
    get_size = get_size,
}
