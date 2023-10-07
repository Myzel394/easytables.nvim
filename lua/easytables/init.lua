local table = require("easytables.table")
local window = require("easytables.window")
local inputHelper = require("easytables.input")
local o = require("easytables.options")

local function create_new_table(cols, rows)
    local markdown_table = table:create(cols, rows)

    local win = window:create(markdown_table)

    win:show()
    win:register_listeners()
    win:draw_table()
end

---Initialize `easytables` with the given options. This function **must** be called.
---@param options table See options.lua for available options
local function setup(options)
    options = options or {}
    o.merge_options(options)

    vim.api.nvim_create_user_command(
        "EasyTablesCreateNew",
        function(opt)
            local input = opt.args

            local success, result = pcall(function() return inputHelper.extract_column_info(input) end)

            if not success then
                error("Don't know how to interpret this message. Please use a format like 3x4 or 3x or 4 or x5")
                return
            end

            -- tuple do not seem to be working with pcall
            local cols = result[1]
            local rows = result[2]

            create_new_table(cols, rows)
        end,
        {
            nargs = 1,
            desc = "Create a new markdown table using EasyTables"
        }
    )
end

return {
    setup = setup,
}
