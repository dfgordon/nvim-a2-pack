local M = {}
local _config = {}

function M.setup(config)
	 _config = config
end

local commands = require("commands")
commands.create_commands()

local function get_workspace_dir(args)
	local root_dir = vim.fn.getcwd()
	local git_dir = vim.fs.root(args.buf, { '.git' })
	if git_dir ~= nil then
		root_dir = git_dir
	end
	return root_dir
end

vim.api.nvim_create_autocmd('FileType', {
	pattern = 'applesoft',
	callback = function(args)
		vim.lsp.start({
			name = 'server-applesoft',
			cmd = {'server-applesoft'},
			root_dir = get_workspace_dir(args),
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
			root_dir = get_workspace_dir(args),
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
			root_dir = get_workspace_dir(args),
			settings = _config,
            handlers = {
                ["workspace/executeCommand"] = commands.finish_command
			}
		})
	end,
})

return M
