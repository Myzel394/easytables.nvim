local Input = require("nui.input")
local event = require("nui.utils.autocmd").event
local table = require("easytables.table")
local window = require("easytables.window")

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
    print("size")
    print(#"┐┐")
    print(vim.api.nvim_strwidth("┐┐"))
    local own_table = table:create(6, 3)
    own_table:highlight_cell(1, 1)

    local window = window:create()

    window:show()
    window:draw_table(own_table)
    window:register_listeners(own_table)
end

return {
    a = a,
    get_size = get_size,
}
