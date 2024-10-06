--- :A2 minify {level?} - reduce size of Applesoft code and open in new window
--- 
--- :A2 tokenize {load_addr?} - Display hex dump of tokenized code in new window.
---     For Integer BASIC load_addr is the *end* of the tokens, and has no effect
---     on the tokenized datastream itself.
---
--- :A2 renumber {start} {step} - Renumber a BASIC program.
---     This will move lines if necessary.  Operates on selection, or whole program
---     if there is none.  References are updated globally.

local display = require "display"

local commands = {}

commands.load_addr = 0

---@class A2Cmd
---@field impl fun(args:string[], opts: vim.api.keyset.user_command) The command implementation
---@field complete? fun(subcmd_arg_lead: string): string[] Command completions callback, taking the lead of the subcommand's arguments

---Table containing the subcommand implementation and completions
---@type { [string]: A2Cmd }
local a2_command_tbl = {
    minify = {
        impl = function(args, opts)
            if #args > 1 then
                vim.print("expected 0 or 1 args, got " .. #args)
                return
            end
            local ft = vim.api.nvim_get_option_value('filetype', { buf = 0 })
            if ft ~= "applesoft" then
                vim.print("can't minify " .. ft)
                return
            end
            local level = tonumber(1)
            if #args > 0 then
                level = tonumber(args[1])
            end
            vim.lsp.buf.execute_command {
                command = 'applesoft.minify',
                arguments = {
                    vim.fn.join(vim.fn.getbufline(vim.fn.bufname("%"), 0, "$"), "\n"),
                    level
                }
            }
        end,
        complete = function (subcmd_arg_lead)
            return {"1","2","3"}
        end
    },
    tokenize = {
        impl = function(args, opts)
            if #args > 1 then
                vim.print("expected 0 or 1 args, got " .. #args)
                return
            end
            local ft = vim.api.nvim_get_option_value('filetype', { buf = 0 })
            local arguments = {}
            if ft == "applesoft" then
                if #args > 0 then
                    commands.load_addr = tonumber(args[1])
                else
                    commands.load_addr = tonumber(2049)
                end
                arguments = {
                    vim.fn.join(vim.fn.getbufline(vim.fn.bufname("%"), 0, "$"), "\n"),
                    commands.load_addr
                }
            elseif ft == "integerbasic" then
                if #args > 0 then
                    commands.load_addr = tonumber(args[1])
                else
                    commands.load_addr = tonumber(38400)
                end
                arguments = {
                    vim.fn.join(vim.fn.getbufline(vim.fn.bufname("%"), 0, "$"), "\n")
                }
            else
                vim.print("can't tokenize " .. ft)
                return
            end
            vim.lsp.buf.execute_command {
                command = ft..'.tokenize',
                arguments = arguments
            }
        end,
        complete = function (subcmd_arg_lead)
            local ft = vim.api.nvim_get_option_value('filetype', { buf = 0 })
            if ft == "applesoft" then
                return {"2049","16385"}
            else
                return {"38400"}
            end
        end
    },
    renumber = {
        impl = function(args, opts)
            local ft = vim.api.nvim_get_option_value('filetype', { buf = 0 })
            if ft ~= "applesoft" and ft ~= "integerbasic" then
                vim.print("can't renumber " .. ft)
                return
            end
            if #args ~= 2 then
                vim.print("expected 2 args, got " .. #args)
                return
            end
            local textDocumentItem = {
                uri = vim.lsp.util.make_text_document_params().uri,
                languageId = ft,
                version = 0, -- where to get the right version?
                text = vim.fn.join(vim.fn.getbufline(vim.fn.bufname("%"), 0, "$"), "\n")
            }
            local rng = vim.lsp.util.make_given_range_params().range
            if rng.start.line == rng['end'].line then
                rng = nil
            end
            vim.lsp.buf.execute_command {
                command = ft .. '.move',
                arguments = {
                    textDocumentItem,
                    rng,
                    args[1],
                    args[2],
                    true
                }
            }
        end,
        complete = function (subcmd_arg_lead)
            return {"1","10"}
        end
    }
}

---Get a name in the form untitled<n>.<ext>, choosing n
---for uniqueness.  Returns nil after 1000 tries.
local function next_untitled_doc(ext)
    local base = 'untitled'
    local suf = 0
    while vim.fn.bufexists(base .. '.' .. ext) ~= 0 do
        suf = suf + 1
        base = base .. suf
        if suf == 1000 then
            return nil
        end
    end
    return base .. '.' .. ext
end

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

---Process server's response to executeCommand request
function commands.finish_command(err, result, ctx, config)
    if err ~= nil then
        vim.print(ctx.params.command .. ' failed: ' .. err.message)
        return
    end
    if string.find(ctx.params.command, ".move") ~= nil then
        if string.find(ctx.params.command, "integerbasic") ~= nil then
            vim.print("if code branches on expressions they may need manual adjustment")
        end
        -- no need for other action, lsp client handles the returned edits
        return
    end
    if result ~= nil then
        if ctx.params.command == "applesoft.minify" then
            local doc_name = next_untitled_doc('bas')
            if doc_name == nil then
                vim.print('too many untitled docs')
                return
            end
            local bufnr = vim.fn.bufnr(doc_name,true)
            vim.fn.bufload(bufnr)
            vim.fn.setbufline(bufnr, 1, vim.fn.split(result, "\n"))
            vim.api.nvim_open_win(bufnr, false, { split = 'right', win = 0 })
        end
        if string.find(ctx.params.command, ".tokenize") ~= nil then
            local neg = false
            if ctx.params.command == "integerbasic.tokenize" then
                commands.load_addr = commands.load_addr - #result
                neg = true
            end
            local doc_name = next_untitled_doc('txt')
            if doc_name == nil then
                vim.print('too many untitled docs')
                return
            end
            local bufnr = vim.fn.bufnr(doc_name,true)
            vim.fn.bufload(bufnr)
            vim.fn.setbufline(bufnr, 1, vim.fn.split(display.hexdump(result, commands.load_addr, neg), "\n"))
            vim.api.nvim_open_win(bufnr, false, { split = 'right', win = 0 })
        end
	else
        vim.print("nil result from executeCommand")
    end
end

return commands