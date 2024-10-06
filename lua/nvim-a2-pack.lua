local M = {}
local _config = {}

function M.setup(config)
	 _config = config
end

local commands = require("commands")
commands.create_commands()

vim.api.nvim_create_autocmd('FileType', {
	pattern = 'applesoft',
	callback = function(args)
		vim.lsp.start({
			name = 'server-applesoft',
			cmd = {'server-applesoft'},
			root_dir = vim.fs.root(args.buf,{'.git'}),
            settings = _config,
            handlers = {
                ["workspace/executeCommand"] = commands.finish_command
			}
        })
	end,
})

vim.api.nvim_create_autocmd('FileType', {
	pattern = 'integerbasic',
	callback = function(args)
		vim.lsp.start({
			name = 'server-integerbasic',
			cmd = {'server-integerbasic'},
			root_dir = vim.fs.root(args.buf,{'.git'}),
			settings = _config,
            handlers = {
                ["workspace/executeCommand"] = commands.finish_command
			}
		})
	end,
})

vim.api.nvim_create_autocmd('FileType', {
	pattern = 'merlin',
	callback = function(args)
		vim.lsp.start({
			name = 'server-merlin',
			cmd = {'server-merlin'},
			root_dir = vim.fs.root(args.buf,{'.git'}),
			settings = _config,
            handlers = {
                ["workspace/executeCommand"] = commands.finish_command
			}
		})
	end,
})

return M
