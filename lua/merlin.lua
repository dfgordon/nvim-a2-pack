local dimg = require "disk-image"
local dasm = require "disassembly"

local merlin = {}

---cannot be passed directly to server, use function merlin.put
merlin.put_args = {
    path = "",
    text = "",
    uri = ""
}

function merlin.put()
    vim.lsp.buf.execute_command {
        command = "merlin6502.disk.put",
        arguments = {
            merlin.put_args.path,
            merlin.put_args.text,
            merlin.put_args.uri
        }
    }
end

function merlin.decode(result)
    -- build slice the hard way (unpack(img,3) does not work due to 8K limit)
    local slice = {}
    for i = 3,#result do
        slice[i-2] = tonumber(result[i])
    end
    vim.lsp.buf.execute_command {
        command = "merlin6502.detokenize",
        arguments = {
            slice
        }
    }
end

function merlin.is_source(result)
    -- Merlin source is all negative except for 0x20, which is used for space, because 0xa0 is the column separator.
    -- We also allow for 0x09 (HTAB, don't remember justification)
    for i = 3, #result do
        if result[i] < 128 and result[i] ~= 0x20 and result[i] ~= 0x09 then
            return false
        end
    end
    return true
end

---Process server's response to executeCommand request
function merlin.finish_command(err, result, ctx, config)
    if err ~= nil then
        if dimg.is_completion() then
            vim.notify("not a directory",vim.log.levels.info)
        else
            vim.notify(ctx.params.command .. ' failed: ' .. err.message, vim.log.levels.ERROR)
        end
        return
    end
    -- first handle commands where nil result is OK
    if ctx.params.command == "merlin6502.toData" or ctx.params.command == "merlin6502.toCode" then
        local ws_edit = {
            changes = {}
        }
        local rng = {}
        rng['start'] =  { line = ctx.params.arguments[3], character = 0 }
        rng['end'] =  { line = ctx.params.arguments[4], character = 0 }
        ws_edit.changes[ctx.params.arguments[2]] = { {range = rng, newText = result} }
        vim.lsp.util.apply_workspace_edit(ws_edit,'utf-8')
        return
    elseif ctx.params.command == "merlin6502.disk.mount" then
        dimg.curr_listing = {}
        dimg.mounted.merlin6502 = ctx.params.arguments[1]
        vim.notify("buffer of " .. ctx.params.arguments[1] .. " is mounted", vim.log.levels.INFO)
        return
    elseif ctx.params.command == "merlin6502.disk.put" then
        vim.notify(ctx.params.arguments[1] .. " saved to disk image", vim.log.levels.INFO)
        return
    elseif ctx.params.command == "merlin6502.disk.delete" then
        local call_ctx = table.remove(dimg.pipeline)
        if call_ctx == dimg.PUT then
            merlin.put()
        end
        return
    end

    -- next handle commands where nil result is an error
    if result ~= nil then
        if ctx.params.command == "merlin6502.detokenize" then
            vim.fn.append(vim.fn.line("."), vim.fn.split(result, "\n"))
        elseif ctx.params.command == "merlin6502.disassemble" then
            vim.fn.append(vim.fn.line("."), vim.fn.split(result, "\n"))
        elseif ctx.params.command == "merlin6502.disk.pick" then
            local call_ctx = table.remove(dimg.pipeline)
            if call_ctx == dimg.COMP then
                dimg.parse_dir(result)
            elseif call_ctx == dimg.LOAD then
                if merlin.is_source(result) then
                    merlin.decode(result)
                else
                    dasm.from_disk_image(result)
                end
            elseif call_ctx == dimg.CHECK then
                merlin.put_args.path = dimg.save_path
                merlin.put_args.text = vim.fn.join(vim.fn.getbufline(vim.fn.bufname("%"), 0, "$"), "\n")
                merlin.put_args.uri = vim.uri_from_bufnr(0)
                dimg.check(result, merlin.put)
            end
        end
    else
        vim.notify("nil result from " .. ctx.params.command, vim.log.levels.WARN)
    end
end

return merlin