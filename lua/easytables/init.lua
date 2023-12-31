local table = require("easytables.table")
local window = require("easytables.window")
local inputHelper = require("easytables.input")
local o = require("easytables.options")
local export = require("easytables.export")
local import = require("easytables.import")

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

            -- tuples do not seem to be working with pcall
            local cols = result[1]
            local rows = result[2]

            local markdown_table = table:create(cols, rows)

            local win = window:create(
                markdown_table,
                {
                    on_export = function()
                        local new_table = export:export_table(markdown_table)

                        vim.schedule(function()
                            local cursor = vim.api.nvim_win_get_cursor(0)

                            vim.api.nvim_buf_set_text(
                                0,
                                cursor[1] - 1,
                                cursor[2],
                                cursor[1] - 1,
                                cursor[2],
                                new_table
                            )
                        end)
                    end
                }
            )

            win:show()
            win:register_listeners()
            win:draw_table()
        end,
        {
            nargs = 1,
            desc = "Create a new markdown table using EasyTables"
        }
    )

    vim.api.nvim_create_user_command(
        "EasyTablesImportThisTable",
        function()
            local buffer = vim.api.nvim_get_current_buf()
            local start_row = import.find_row_start(buffer)

            if not start_row then
                error("No table found (failed to find start row)")
                return
            end

            local end_row = import.find_row_end(buffer, start_row)

            if not end_row then
                error("No table found (failed to find end row)")
                return
            end

            local raw_table = import.extract_table(buffer, start_row, end_row)

            local markdown_table = table:import(raw_table)

            local win = window:create(
                markdown_table,
                {
                    on_export = function()
                        local new_table = export:export_table(markdown_table)

                        vim.schedule(function()
                            -- Remove old table
                            vim.api.nvim_buf_set_lines(buffer, start_row, end_row, false, new_table)
                        end)
                    end
                }
            )

            win:show()
            win:register_listeners()
            win:draw_table()
        end,
        {
            desc = "Import the current markdown table at the cursor's position into EasyTables"
        }
    )
end

return {
    setup = setup,
}
