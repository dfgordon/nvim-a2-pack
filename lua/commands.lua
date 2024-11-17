--- Main command processor.
--- Commands begin with `:A2`, subcommands are handled in modules.

local dimg = require "disk-image"
local xfrm = require "transform"

local commands = {}

---@class A2Cmd
---@field impl fun(args:string[], opts: any) The command implementation
---@field complete? fun(subcmd_arg_lead: string): string[] Command completions callback, taking the lead of the subcommand's arguments

---Table containing the subcommand implementation and completions
---@type { [string]: A2Cmd }
local a2_command_tbl = {
    mount = dimg.mount,
    load = dimg.load,
    save = dimg.save,
    minify = xfrm.minify,
    renumber = xfrm.renumber,
    tokenize = xfrm.tokenize,
    asm = xfrm.asm,
    dasm = xfrm.dasm
}

---Parse options and dispatch subcommand
local function dispatcher(opts)
    local fargs = opts.fargs
    local cmd = fargs[1]
    local args = #fargs > 1 and vim.list_slice(fargs, 2, #fargs) or {}
    local command = a2_command_tbl[cmd]
    if not command then
        vim.notify("A2: Unknown command: " .. cmd, vim.log.levels.ERROR)
        return
    end
    command.impl(args, opts)
end

---Set up the main command, always invoked with `:A2`.
---Only the subcommands actually carry out any action.
function commands.create_commands()
    vim.api.nvim_create_user_command("A2", dispatcher, {
        nargs = "+",
        desc = "Apple II language services",
        complete = function(arg_lead, cmdline, _)
            -- first see if we are completing an argument
            local subcmd, subcmd_arg_lead = cmdline:match("^A2[!]*%s(%S+)%s(.*)$")
            if subcmd and subcmd_arg_lead and a2_command_tbl[subcmd] and a2_command_tbl[subcmd].complete then
                return a2_command_tbl[subcmd].complete(subcmd_arg_lead)
            end
            -- if not complete the subcommand
            if cmdline:match("^A2[!]*%s+%w*$") then
                return vim.iter(vim.tbl_keys(a2_command_tbl)):totable()
            end
        end,
        bang = true,
    })
end

return commands