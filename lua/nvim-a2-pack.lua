local abas = require "applesoft"
local ibas = require "integerbasic"
local merlin = require "merlin"

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

local function check_neovim_version()
    local version = vim.fn.api_info().version
    local vers_str = version.major .. "." .. version.minor .. "." .. version.patch
    if version.major > 0 then
        vim.notify("Neovim version is " .. vers_str .. ", expected 0.x", vim.log.levels.WARN)
    end
    if version.minor < 11 then
        vim.notify("minor version is " .. vers_str .. ", expected 11.x", vim.log.levels.WARN)
    end
end

local function check_server_version(client,init_result)
    local version = client.server_info.version
	if string.sub(version,1,1) ~= "4" then
		vim.notify("server version is "..version..", expected 4.x", vim.log.levels.WARN)
	end
end


vim.api.nvim_create_autocmd('FileType', {
	pattern = 'applesoft',
    callback = function(args)
		check_neovim_version()
		vim.lsp.start({
			name = 'server-applesoft',
			cmd = {'server-applesoft'},
			root_dir = get_workspace_dir(args),
            settings = _config,
            handlers = {
                ["workspace/executeCommand"] = abas.finish_command
            },
			on_init = check_server_version
        })
	end,
})

vim.api.nvim_create_autocmd('FileType', {
	pattern = 'integerbasic',
	callback = function(args)
		check_neovim_version()
		vim.lsp.start({
			name = 'server-integerbasic',
			cmd = {'server-integerbasic'},
			root_dir = get_workspace_dir(args),
			settings = _config,
            handlers = {
                ["workspace/executeCommand"] = ibas.finish_command
			},
			on_init = check_server_version
		})
	end,
})

vim.api.nvim_create_autocmd('FileType', {
	pattern = 'merlin',
	callback = function(args)
		check_neovim_version()
		vim.lsp.start({
			name = 'server-merlin',
			cmd = {'server-merlin'},
			root_dir = get_workspace_dir(args),
			settings = _config,
            handlers = {
                ["workspace/executeCommand"] = merlin.finish_command
			},
			on_init = check_server_version
		})
	end,
})

return M
