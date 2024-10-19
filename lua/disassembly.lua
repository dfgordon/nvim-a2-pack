local mimg = require "memory-image"

local dasm = {}

dasm.rng_type = "range"
dasm.addrRange = { 0, 0 }
dasm.xc = 0
dasm.mx = 3
dasm.label = "some"

---user is only prompted for arguments that are nil
function dasm.input_params(rng_type,beg,ending,xc,mx,label)
    if rng_type == nil then
        local r = vim.fn.confirm("select binary source", "&1last DOS 3.3 bload\n&2last ProDOS bload\n&3explicit range", "Question")
        if r == 0 then
            return false
        elseif r == 1 then
            dasm.rng_type = "last dos33 bload"
        elseif r == 2 then
            dasm.rng_type = "last prodos bload"
        elseif r == 3 then
            dasm.rng_type = "range"
            local b = tonumber(vim.fn.input("enter starting address: "))
            local e = tonumber(vim.fn.input("enter ending address: "))
            if b >= e or b < 0 or e > 0xffff then
                vim.notify("invalid parameters", vim.log.levels.ERROR)
                return false
            end
            dasm.addrRange = { b, e }
        end
    else
        dasm.rng_type = rng_type
        dasm.addr_range = { beg, ending }
    end
    
    if xc == nil then
        local proc = vim.fn.confirm("select processor", "&16502\n&265c02\n&365816", "Question")
        if proc == 0 then
            return false
        end
        dasm.xc = proc - 1
    else
        dasm.xc = xc
    end

    if mx == nil and dasm.xc == 2 then
        local bits = vim.fn.confirm("MX status bits", "&100\n&201\n&310\n&411", "Question")
        if bits == 0 then
            return false
        end
        dasm.mx = bits - 1
    else
        if mx == nil then
            dasm.mx = 3
        else
            dasm.mx = mx
        end
    end

    if label == nil then
        local l = vim.fn.confirm("select label density", "&1none\n&2some\n&3all", "Question")
        if l == 0 then
            return false
        elseif l == 1 then
            dasm.label = "none"
        elseif l == 2 then
            dasm.label = "some"
        elseif l == 3 then
            dasm.label = "all"
        end
    else
        dasm.label = label
    end

    return true
end

function dasm.from_disk_image(result)
    mimg.init()
    mimg.finish_bload(result)
    if dasm.input_params("last prodos bload",0,0,nil,nil,nil) then
        vim.lsp.buf.execute_command {
            command = "merlin6502.disassemble",
            arguments = {
                mimg.main,
                tonumber(dasm.addrRange[1]),
                tonumber(dasm.addrRange[2]),
                dasm.rng_type,
                tonumber(dasm.xc),
                tonumber(dasm.mx),
                dasm.label
            }
        }
    end
end

return dasm