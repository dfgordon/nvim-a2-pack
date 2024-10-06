local display = {}

function display.hexdump(ary,load_addr,neg)
    local dump = ""
    local hex = ""
    local asc = ""

    for i = 1,#ary do
        if 1 == i % 8 then
            dump = dump .. hex .. asc .. "\n"
            hex = string.format("%04x: ", load_addr + i - 1)
            asc = ""
        end

        hex = hex .. string.format("%02x ", ary[i])
        if neg then
            if ary[i] >= 128 + 32 and ary[i] <= 128 + 126 then
                asc = asc .. string.char(ary[i] - 128)
            else
                asc = asc .. "."
            end
        else
            if ary[i] >= 32 and ary[i] <= 126 then
                asc = asc .. string.char(ary[i])
            else
                asc = asc .. "."
            end
        end
    end


    return dump .. hex
        .. string.rep("   ", 8 - #ary % 8) .. asc
end

return display