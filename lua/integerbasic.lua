local display = require "display"
local dimg = require "disk-image"

local ibas = {}

ibas.load_addr = 0

---cannot be passed directly to server, use function ibas.put
ibas.put_args = {
    path = "",
    text = ""
}

function ibas.put()
    vim.lsp.buf.execute_command {
        command = "integerbasic.disk.put",
        arguments = {
            ibas.put_args.path,
            ibas.put_args.text
        }
    }
end

---Process server's response to executeCommand request
function ibas.finish_command(err, result, ctx, config)
    if err ~= nil then
        if dimg.is_completion() then
            vim.notify("not a directory",vim.log.levels.info)
        else
            vim.notify(ctx.params.command .. ' failed: ' .. err.message, vim.log.levels.ERROR)
        end
        return
    end
    -- first handle commands where nil result is OK
    if ctx.params.command == "integerbasic.move" then
        vim.notify("if code branches on expressions they may need manual adjustment", vim.log.levels.WARN)
        -- no need for other action, lsp client handles the returned edits
        return
    elseif ctx.params.command == "integerbasic.disk.mount" then
        dimg.curr_listing = {}
        dimg.mounted.integerbasic = ctx.params.arguments[1]
        vim.notify("buffer of " .. ctx.params.arguments[1] .. " is mounted", vim.log.levels.INFO)
        return
    elseif ctx.params.command == "integerbasic.disk.put" then
        vim.notify(ctx.params.arguments[1] .. " saved to disk image", vim.log.levels.INFO)
        return
    elseif ctx.params.command == "integerbasic.disk.delete" then
        local call_ctx = table.remove(dimg.pipeline)
        if call_ctx == dimg.PUT then
            ibas.put()
        end
        return
    end

    -- next handle commands where nil result is an error
    if result ~= nil then
        if ctx.params.command == "integerbasic.tokenize" then
            ibas.load_addr = ibas.load_addr - #result
            local doc_name = display.next_untitled_doc('txt')
            if doc_name == nil then
                vim.notify('too many untitled docs', vim.log.levels.ERROR)
                return
            end
            local bufnr = vim.fn.bufnr(doc_name,true)
            vim.fn.bufload(bufnr)
            vim.fn.setbufline(bufnr, 1, vim.fn.split(display.hexdump(result, ibas.load_addr, true), "\n"))
            vim.api.nvim_open_win(bufnr, false, { split = 'right', win = 0 })
        elseif ctx.params.command == "integerbasic.disk.pick" then
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
                ibas.put_args.path = dimg.save_path
                ibas.put_args.text = vim.fn.join(vim.fn.getbufline(vim.fn.bufname("%"), 0, "$"), "\n")
                dimg.check(result, ibas.put)
            end
        end
	else
        vim.notify("nil result from " .. ctx.params.command, vim.log.levels.WARN)
    end
end

return ibas