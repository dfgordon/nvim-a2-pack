---Simple model of the Apple II memory
---
---This is/may-be used to store results from various operations:
---* memory state of an emulator
---* binary files read from a disk image
---
---Things that can/could be done with it:
---* get the bytestream associated with the last BLOAD
---* get the resident Applesoft or Integer BASIC program
---* get the resident Merlin source code

local mimg = {}

mimg.main = {}
mimg.aux = {}

local DOS33_START = 0xaa72 + 1
local DOS33_LEN = 0xaa60 + 1
local PRODOS_START = 0xbeb9 + 1
local PRODOS_LEN = 0xbec8 + 1

---initialize main and aux 64K address space to 0
function mimg.init()
    mimg.main = {}
    mimg.aux = {}
    for i = 1, 0x10000 do
        mimg.main[i] = 0
    end
    for i = 1,0x10000 do
        mimg.aux[i] = 0
    end
end

function mimg.dos33_bload_range()
    local start = mimg.main[DOS33_START] + mimg.main[DOS33_START+1] * 0x100
    local length = mimg.main[DOS33_LEN] + mimg.main[DOS33_LEN+1] * 0x100
    local ending = start + length
    if ending > #mimg.main then
        return nil;
    end
    return {start,ending}
end

function mimg.prodos_bload_range()
    local start = mimg.main[PRODOS_START] + mimg.main[PRODOS_START+1] * 0x100
    local length = mimg.main[PRODOS_LEN] + mimg.main[PRODOS_LEN+1] * 0x100
    local ending = start + length
    if ending > #mimg.main then
        return nil;
    end
    return {start,ending}
end

function mimg.dos33_set_bload_range(load_addr, length)
    mimg.main[DOS33_START] = load_addr % 0x100
    mimg.main[DOS33_START+1] = math.floor(load_addr / 0x100)
    mimg.main[DOS33_LEN] = length % 0x100
    mimg.main[DOS33_LEN+1] = math.floor(length / 0x100)
end

function mimg.prodos_set_bload_range(load_addr, length)
    mimg.main[PRODOS_START] = load_addr % 0x100
    mimg.main[PRODOS_START+1] = math.floor(load_addr / 0x100)
    mimg.main[PRODOS_LEN] = length % 0x100
    mimg.main[PRODOS_LEN+1] = math.floor(length / 0x100)
end

---use result from disk image operation to update memory image
function mimg.finish_bload(result)
    local load_addr = result[1] + result[2] * 0x100
    local length = #result - 2
    mimg.prodos_set_bload_range(load_addr, length)
    for i = load_addr, load_addr + length - 1 do
        mimg.main[i+1] = result[i - load_addr + 3]
    end
end

return mimg
