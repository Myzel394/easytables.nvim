<div align="center">

# Easytables

##### Make Markdown tables great again!

</div>

[Preview of usage of easytables](https://github.com/Myzel394/easytables.nvim/assets/50424412/d8bcb0c2-9b8b-468a-b1a8-f0032543f1e9)

**Please note that this is a work in progress.**

## Features

- Preview tables in real time
- Add and remove rows and columns
- Move rows and columns
- Move cells

## Usage

### Installation

Using [packer](https://github.com/wbthomason/packer.nvim):

```lua
use "Myzel394/easytables.nvim"
```

### Tutorial

#### Inserting a new table

Go to the place where you want to insert your table and either call:

* `:EasyTablesCreateNew <width>x<height>` - Creates a new table with `<width>` columns and `<height>` rows
* `:EasyTablesCreateNew <width>` - Creates a square table with the size of `<width>` (eg. `:EasyTablesCreateNew 5` -> Creates a `5x5` table)
* `:EasyTablesCreateNew <width>x` - Creates a table with `<width>` columns and **one** row
* `:EasyTablesCreateNew x<height>` - Creates a table with **one** column and `<height>` rows

#### Editing an existing table

Go to your table (doesn't matter where, can be at a border or inside a cell) and type:

`:EasyTablesImportThisTable`

### Custom Setup

**Make sure to call the `setup` function!**

`after/plugin/easytables.lua`

```lua
require("easytables").setup {
  -- Your configuration comes here
}
```

#### Default configuration

By default, easytables configures default characters for the table and registers the following keymaps:

- `<Left>`: Move cell left (in normal mode, applies to all other directions)
- `<S-Left>`: Swaps cell with cell to the left (in normal mode, applies to all other directions)
- `<C-Left>`: Swaps column with column to the left (in normal mode, applies to all other directions)
- `<Tab`>: Move cell to the next cell (in normal mode, either to the right or to the beginning of the next line)
- `<S-Tab>`: Move cell to the previous cell (in normal mode, either to the left or to the end of the previous line)

This is the default configuration:

```lua
{
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
```

## Limitations

* This plugin currently does not work well with big tables

## This project is stupid, the code is awful, go away

I know that the code is probably not the best, it's my first ever written neovim plugin.
You are more than welcome to contribute to this project, I will gladly accept any help.

## Donate

It might sound crazy, but if you would just donate 1$, it would totally mean to world to me, since
it's a really small amount and if everyone did that, I can totally focus on easytables and my other open
source projects. :)

You can donate via:

- [GitHub Sponsors](https://github.com/sponsors/Myzel394)
- Bitcoin: `bc1qw054829yj8e2u8glxnfcg3w22dkek577mjt5x6`
- Monero: `83dm5wyuckG4aPbuMREHCEgLNwVn5i7963SKBhECaA7Ueb7DKBTy639R3QfMtb3DsFHMp8u6WGiCFgbdRDBBcz5sLduUtm8`
