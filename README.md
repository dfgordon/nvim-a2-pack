# Apple II Languages for Neovim

## Overview

This plugin provides language support for the following languages that were historically used with the Apple II line of computers:

* Integer BASIC
* Applesoft BASIC
* Merlin Assembly

## Installation

1. Install rust if necessary (search for rustup, or perhaps use a package manager, e.g. `brew install rust`).
2. Run `cargo install a2kit` in the terminal.  The a2kit version should be 3.3 or higher.
3. Install this plugin.  This usually means editing a configuration file.  A minimal example for users of [Lazy](https://github.com/folke/lazy.nvim) is shown below.
4. Try `nvim <my_file>.bas`.  If highlights [1] look good you are done.  If not, install a more advanced terminal program, or a Neovim GUI.

[1] You do *not* need `nvim-treesitter`, the semantic highlights provided by the servers are comprehensive

```lua
--- EXAMPLE SPECIFIC TO THE LAZY PLUGIN MANAGER.
--- This file can be named anything.lua.
--- For Windows this goes in ~\AppData\Local\nvim\lua\plugins.
--- For others this goes in ~/.config/nvim/lua/plugins.
return {
  -- add a color scheme
  {
    "sho-87/kanagawa-paper.nvim",
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      vim.cmd.colorscheme('kanagawa-paper')
    end,
  },

  -- add the language servers
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

## Features

What you get for free includes, but is not limited to,

* semantic highlights
* language diagnostics
* go to definition, type `Ctrl-]` with cursor on any kind of reference
* hovers, type  `K` with the cursor on a wide variety of language elements

Completions require a little more effort, see below.

## Settings

Change settings using the plugin module's setup function.  In the case of [Lazy](https://github.com/folke/lazy.nvim) it can be done in declarative fashion:

```lua
return {
  --- same as the spec file above but with custom settings
  --- ...omitting other plugins...
  {
    "dfgordon/nvim-a2-pack",
    opts = {
      merlin6502 = {
        --- server defaults to Merlin 8, change it to Merlin 32
        version = "Merlin 32"
      }
    }
  }
}
```

The available map keys can be found [here](https://github.com/dfgordon/a2kit/wiki/Languages#configuration-options), with the caveat that there is an implied root key corresponding to the language, as follows:

* Merlin = `merlin6502`
* Applesoft = `applesoft`
* Integer BASIC = `integerbasic`

You translate the key paths to Lua maps in the obvious way.

## Completions

The language servers provide completions and snippets.  To gain these capabilities in Neovim you have to configure some plugins.  This can get pretty involved.  Here is an example using [Lazy](https://github.com/folke/lazy.nvim).

```lua
return {
  --- same as the spec file above but with completions plugin
  --- ...omitting other plugins...
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