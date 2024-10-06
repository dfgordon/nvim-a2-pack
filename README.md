# Apple II Languages for Neovim

## Overview

This plugin provides language support for the following languages:

* Integer BASIC
* Applesoft BASIC
* Merlin Assembly

These were commonly used with the Apple II line of computers.

<img src="nvim-a2-pack-demo.gif" alt="session capture"/>

## Features

* semantic highlights
* language diagnostics
* go to definition with `Ctrl-]`
* display hovers with `K`
* auto completions, see below
* minify Applesoft with `:A2 minify [level]`
* tokenize either BASIC with `:A2 tokenize [address]`
  - for Integer, address is *end* of tokens, and only affects display
* renumber either BASIC with `:A2 renumber <start> <step>`
  - renumbers selection, or whole document if none
  - will change row order if necessary

## Installation

1. Install Neovim version 0.10.1 or higher
2. Install `a2kit` version 3.3.2 or higher
    - Install/update the rust toolchain as necessary
    - Run `cargo install a2kit` in the terminal
    - Make sure `~/.cargo/bin` is in the path (usually automatic)
2. Install the plugin.  The procedure varies depending on plugin manager.  See examples.
3. Test it by moving the cursor over some keyword in an Apple II source file, and pressing `K` (case matters) in normal mode.  You should get a hover.  If the color scheme is not rendered properly, try installing a better terminal program, or a Neovim GUI.

The plugin does not verify client or server versions.  You have to check yourself with `a2kit -V` and `nvim -v` (case matters).

### rocks.nvim example

For [rocks.nvim](https://github.com/nvim-neorocks/rocks.nvim), enter Neovim and issue commands:

1. `:Rocks install rocks-config.nvim` (adds ability to configure plugins)
2. `:Rocks install tokyonight.nvim` (color scheme, substitute your favorite)
3. `:Rocks install nvim-a2-pack`

Notes:

* Color scheme is not automatically made the default, see [Settings](#settings).
* As of this writing, using `rocks.nvim` with Windows is challenging.

### lazy.nvim example

For [lazy.nvim](https://github.com/folke/lazy.nvim) you add a line to your spec file.  A minimal example of this file follows.

```lua
--- LAZY.NVIM SPEC FILE
--- This file can be named anything.lua.
--- For Windows this goes in ~\AppData\Local\nvim\lua\plugins.
--- For others this goes in ~/.config/nvim/lua/plugins.
return {
  -- add a color scheme if not already done
  {
    "sho-87/kanagawa-paper.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      -- make it the default
      vim.cmd.colorscheme('kanagawa-paper')
    end,
  },

  -- connect the language servers
  { "dfgordon/nvim-a2-pack", opts = {} },
}
```

## Workspace

Merlin analysis requires a workspace scan.  The way the plugin finds the workspace root is by walking up the directory tree until it finds a `.git` directory.  If your project is not a git repository, you can add an empty `.git` directory to mark the workspace root.

## File Types

* Integer BASIC is triggered by `*.ibas`
* Applesoft BASIC is triggered by `*.bas` or `*.abas`
* Merlin assembly is triggered by `*.s` or `*.asm`
  - Only `*.s` files are detected by the workspace scanner

## Settings

Changing settings means changing a Lua map (this is the way of Neovim).  Some of the available map keys can be found [here](https://github.com/dfgordon/a2kit/wiki/Languages#configuration-options). Translate the key paths to Lua maps in the obvious way.

### rocks.nvim example

Assuming you are not on Windows, create a file `~/.config/nvim/lua/plugins/a2-pack.lua` with the settings.  Example:

```lua
require('nvim-a2-pack').setup {
    merlin6502 = {
        version = "Merlin 32"
        -- ... other settings
    }
    -- ... other languages
}
```

You can also use this approach to set the default color scheme, e.g., create `~/.config/nvim/lua/plugins/tokyonight.lua` with content

```lua
-- set color scheme options
require('tokyonight').setup {
  style = "day"
}
-- make it the default
vim.cmd.colorscheme('tokyonight')
```

### lazy.nvim example

Modify the spec file to include the options.  Example:

```lua
--- LAZY.NVIM SPEC FILE
return {
  -- ...omitting other plugins...
  {
    "dfgordon/nvim-a2-pack",
    opts = {
      merlin6502 = {
        version = "Merlin 32"
        -- ... other settings
      }
      -- ... other languages
    }
  }
}
```

## Completions

The language servers provide completions and snippets.  To gain these capabilities in Neovim you have to configure some plugins.  This can get pretty involved.  Here is an example using [lazy.nvim](https://github.com/folke/lazy.nvim).

```lua
--- LAZY.NVIM SPEC FILE
return {
  -- ...omitting other plugins...
  {
    "hrsh7th/nvim-cmp",
    -- load cmp on InsertEnter
    event = "InsertEnter",
    -- these dependencies will only be loaded when cmp loads
    -- dependencies are always lazy-loaded unless specified otherwise
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "neovim/nvim-lspconfig",
      "L3MON4D3/LuaSnip"
    },
    config = function ()
	    local cmp = require("cmp")
	    cmp.setup({
		    mapping = cmp.mapping.preset.insert({
			    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
			    ['<C-f>'] = cmp.mapping.scroll_docs(4),
			    ['<C-o>'] = cmp.mapping.complete(),
			    ['<C-e>'] = cmp.mapping.abort(),
			    ['<CR>'] = cmp.mapping.confirm({select = true}),
		    }),
		    snippet = {
			    expand = function(args)
				    require('luasnip').lsp_expand(args.body)
			    end
		    },
		    sources = cmp.config.sources({
			    { name = 'nvim_lsp' },
			    { name = 'luasnip' },
        -- for more aggressive completions uncomment the following lines
		    --}, {
			  --  { name = 'buffer' },
		    })
	    })
    end
  },
}
```

## Notable Non-Dependencies

Neither `lspconfig` nor `nvim-treesitter` are needed by this plugin.

If you want syntax highlights without LSP, you could in theory use `nvim-treesitter`.  The required parsers exist.  However, Merlin requires the LSP for the most accurate highlights.

As of this writing, `a2kit` language servers are not registered with `lspconfig`.

