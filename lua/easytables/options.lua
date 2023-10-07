-- All available options are listed below. The default values are shown.
local options = {
    table = {
        -- Whether to enable the header by default
        header_enabled_by_default = true,
        window = {
            preview_title = "Table Preview",
            prompt_title = "Cell content",
            -- Either "auto" to automatically size the window, or a string
            -- in the format of "<width>x<height>" (e.g. "20x10")
            size = "auto"
        },
        cell = {
            -- Min width of a cell (excluding padding)
            min_width = 3,
            -- Filler character for empty cells
            filler = " ",
            align = "left",
        },
        -- Characters used to draw the table
        -- Do not worry about multibyte characters, they are handled correctly
        border = {
            top_left = "┌",
            top_right = "┐",
            bottom_left = "└",
            bottom_right = "┘",
            horizontal = "─",
            vertical = "│",
            left_t = "├",
            right_t = "┤",
            top_t = "┬",
            bottom_t = "┴",
            cross = "┼",
            header_left_t = "╞",
            header_right_t = "╡",
            header_bottom_t = "╧",
            header_cross = "╪",
            header_horizontal = "═",
        }
    },
    export = {
        markdown = {
            -- Padding around the cell content, applied BOTH left AND right
            -- E.g: padding = 1, content = "foo" -> " foo "
            padding = 1,
            -- What markdown characters are used for the export, you probably
            -- don't want to change these
            characters = {
                horizontal = "-",
                vertical = "|",
                -- Filler for padding
                filler = " "
            }
        }
    },
    set_mappings = function(buf)
        vim.api.nvim_buf_set_keymap(
            buf,
            "n",
            "<Left>",
            ":JumpLeft<CR>",
            {}
        )
        vim.api.nvim_buf_set_keymap(
            buf,
            "n",
            "<S-Left>",
            ":SwapWithLeftCell<CR>",
            {}
        )

        vim.api.nvim_buf_set_keymap(
            buf,
            "n",
            "<Right>",
            ":JumpRight<CR>",
            {}
        )
        vim.api.nvim_buf_set_keymap(
            buf,
            "n",
            "<S-Right>",
            ":SwapWithRightCell<CR>",
            {}
        )

        vim.api.nvim_buf_set_keymap(
            buf,
            "n",
            "<Up>",
            ":JumpUp<CR>",
            {}
        )
        vim.api.nvim_buf_set_keymap(
            buf,
            "n",
            "<S-Up>",
            ":SwapWithUpperCell<CR>",
            {}
        )

        vim.api.nvim_buf_set_keymap(
            buf,
            "n",
            "<Down>",
            ":JumpDown<CR>",
            {}
        )
        vim.api.nvim_buf_set_keymap(
            buf,
            "n",
            "<S-Down>",
            ":SwapWithLowerCell<CR>",
            {}
        )

        vim.api.nvim_buf_set_keymap(
            buf,
            "n",
            "<Tab>",
            ":JumpToNextCell<CR>",
            {}
        )
        vim.api.nvim_buf_set_keymap(
            buf,
            "n",
            "<S-Tab>",
            ":JumpToPreviousCell<CR>",
            {}
        )

        vim.api.nvim_buf_set_keymap(
            buf,
            "n",
            "<C-Left>",
            ":SwapWithLeftColumn<CR>",
            {}
        )
        vim.api.nvim_buf_set_keymap(
            buf,
            "n",
            "<C-Right>",
            ":SwapWithRightColumn<CR>",
            {}
        )
        vim.api.nvim_buf_set_keymap(
            buf,
            "n",
            "<C-Up>",
            ":SwapWithUpperRow<CR>",
            {}
        )
        vim.api.nvim_buf_set_keymap(
            buf,
            "n",
            "<C-Down>",
            ":SwapWithLowerRow<CR>",
            {}
        )
    end
}

-- You can ignore everything below this line

local function merge_tables(t1, t2)
    for k, v in pairs(t2) do
        if type(v) == "table" then
            if type(t1[k] or false) == "table" then
                merge_tables(t1[k] or {}, t2[k] or {})
            else
                t1[k] = v
            end
        else
            t1[k] = v
        end
    end
end

local function merge_options(user_options)
    merge_tables(options, user_options)
end

return {
    merge_options = merge_options,
    options = options
}
