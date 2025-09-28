local display = require "display"
local dimg = require "disk-image"
local abas = {}

---cannot be passed directly to server, use function abas.put
abas.put_args = {
    path = "",
    text = "",
    load_addr = 0
}

function abas.is_addr_bad(addr)
    if tonumber(addr) < 0x200 or tonumber(addr) > 0xfff0 then
        vim.notify("address must be in range 0x200 - 0xfff0", vim.log.levels.ERROR)
        return true
    end
    return false
end

function abas.run(cmd, args)
    dimg.run(cmd, args, "server-applesoft")
end

function abas.put()
    abas.run("applesoft.disk.put", {
        abas.put_args.path,
        abas.put_args.text,
        abas.put_args.load_addr
    })
end

---Process server's response to executeCommand request
function abas.finish_command(err, result, ctx, config)
    if err ~= nil then
        if dimg.is_completion() then
            vim.notify("not a directory",vim.log.levels.info)
        else
            vim.notify(ctx.params.command .. ' failed: ' .. err.message, vim.log.levels.ERROR)
        end
        return
    end
    -- first handle commands where nil result is OK
    if ctx.params.command == "applesoft.move" then
        -- no need for other action, lsp client handles the returned edits
        return
    elseif ctx.params.command == "applesoft.disk.mount" then
        dimg.curr_listing = {}
        dimg.mounted.applesoft = ctx.params.arguments[1]
        vim.notify("buffer of " .. ctx.params.arguments[1] .. " is mounted", vim.log.levels.INFO)
        return
    elseif ctx.params.command == "applesoft.disk.put" then
        vim.notify(ctx.params.arguments[1] .. " saved to disk image", vim.log.levels.INFO)
        return
    elseif ctx.params.command == "applesoft.disk.delete" then
        local call_ctx = table.remove(dimg.pipeline)
        if call_ctx == dimg.PUT then
            abas.put()
        end
        return
    end

    -- next handle commands where nil result is an error
    if result ~= nil then
        if ctx.params.command == "applesoft.minify" then
            local doc_name = display.next_untitled_doc('bas')
            if doc_name == nil then
                vim.notify('too many untitled docs', vim.log.levels.ERROR)
                return
            end
            local bufnr = vim.fn.bufnr(doc_name,true)
            vim.fn.bufload(bufnr)
            vim.fn.setbufline(bufnr, 1, vim.fn.split(result, "\n"))
            vim.api.nvim_open_win(bufnr, false, { split = 'right', win = 0 })
        elseif ctx.params.command == "applesoft.tokenize" then
            local doc_name = display.next_untitled_doc('txt')
            if doc_name == nil then
                vim.notify('too many untitled docs', vim.log.levels.ERROR)
                return
            end
            local bufnr = vim.fn.bufnr(doc_name,true)
            vim.fn.bufload(bufnr)
            vim.fn.setbufline(bufnr, 1, vim.fn.split(display.hexdump(result, abas.put_args.load_addr, false), "\n"))
            vim.api.nvim_open_win(bufnr, false, { split = 'right', win = 0 })
        elseif ctx.params.command == "applesoft.disk.pick" then
            local call_ctx = table.remove(dimg.pipeline)
            if call_ctx == dimg.COMP then
                dimg.parse_dir(result)
            elseif call_ctx == dimg.LOAD then
                if type(result) == "string" then
                    vim.fn.append(vim.fn.line("."), vim.fn.split(result, "\n"))
                else
                    vim.notify("result could not be inserted", vim.log.levels.ERROR)
                end
            elseif call_ctx == dimg.CHECK then
                abas.put_args.load_addr = tonumber(vim.fn.input("enter load address: "))
                if abas.is_addr_bad(abas.put_args.load_addr) then
                    return
                end
                abas.put_args.path = dimg.save_path
                abas.put_args.text = vim.fn.join(vim.fn.getbufline(vim.fn.bufname("%"), 0, "$"), "\n")
                dimg.check(result, abas.put)
            end
        end
	else
        vim.notify("nil result from " .. ctx.params.command, vim.log.levels.WARN)
    end
end

return abas