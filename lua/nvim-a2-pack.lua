local M = {}
local _config = {}

function M.setup(config)
	 _config = config
end

vim.api.nvim_create_autocmd('FileType', {
	pattern = 'applesoft',
	callback = function(args)
		vim.lsp.start({
			name = 'server-applesoft',
			cmd = {'server-applesoft'},
			root_dir = vim.fs.root(args.buf,{'.git'}),
			settings = _config
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
			settings = _config
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
			settings = _config
		})
	end,
})

return M
