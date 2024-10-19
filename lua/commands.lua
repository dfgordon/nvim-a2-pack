--- :A2 minify {level?} - reduce size of Applesoft code and open in new window
--- 
--- :A2 tokenize {load_addr?} - Display hex dump of tokenized code in new window.
---     For Integer BASIC load_addr is the *end* of the tokens, and has no effect
---     on the tokenized datastream itself.
---
--- :A2 renumber {start} {step} - Renumber a BASIC program.
---     This will move lines if necessary.  Operates on selection, or whole program
---     if there is none.  References are updated globally.
---
--- :A2 mount {path} - mount a disk image
---
--- :A2 load {path} - load a file from a disk image and display in editor.
---     BASIC programs will be detokenized, Merlin sources will be decoded,
---     and binary files will be disassembled.

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
    asm = xfrm.asm
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