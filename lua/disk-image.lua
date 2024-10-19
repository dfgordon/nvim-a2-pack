local dimg = {}

dimg.FNAME_START = 13

---picker was invoked by completion
dimg.COMP = "comp"
---picker was invoked by load
dimg.LOAD = "load"
---picker was invoked by save
dimg.CHECK = "check"
---delete was invoked by check
dimg.PUT = "put"

---holds the parsed result of the pick request
dimg.curr_listing = {}
---identifies the stage we are at during a chain of asynchronous requests
dimg.pipeline = {}
---holds the full path of the file we are trying to save
dimg.save_path = ""

---disk images mounted by the given server
dimg.mounted = {
    applesoft = nil,
    integerbasic = nil,
    merlin6502 = nil
}

dimg.file_filter = {
    "d13",
    "do",
    "po",
    "dsk",
    "nib",
    "2mg",
    "2img",
    "woz"
}

function dimg.is_completion()
    if #dimg.pipeline > 0 then
        if dimg.pipeline[#dimg.pipeline] == dimg.COMP then
            return true
        end
    end
    return false
end

---select server based on the current buffer's filetype
function dimg.get_server()
    local ft = vim.api.nvim_get_option_value("filetype", { buf = 0 })
    if ft == "applesoft" then
        return "applesoft"
    elseif ft == "integerbasic" then
        return "integerbasic"
    elseif ft == "merlin" then
        return "merlin6502"
    end
    return nil
end

---filter for pick operations based on current buffer's filetype
function dimg.get_filter()
    local ft = vim.api.nvim_get_option_value("filetype", { buf = 0 })
    local whitelist = {}
    if ft == "merlin" then
        whitelist = { "txt", "bin" }
    elseif ft == "applesoft" then
        whitelist = { "bas" }
    elseif ft == "integerbasic" then
        whitelist = { "int" }
    end
    return whitelist
end

---parse picker result and load `dimg.curr_listing` with {key=filename, val=type}
function dimg.parse_dir(rows)
    dimg.curr_listing = {}
    if type(rows) == "table" then
        for _, row in ipairs(rows) do
            if type(row) ~= "string" then
                return
            end
            dimg.curr_listing[string.sub(row, dimg.FNAME_START)] = string.sub(row, 1, 3)
        end
        return true
    else
        return false
    end
end

---(async) given picker result, does file to be saved already exist.
---If yes we have to query the user and add a delete step before saving.
---Otherwise go immediately to save.
function dimg.check(rows,put_func)
    local s = dimg.get_server()
    local exists = false
    if s ~= nil then
        if dimg.parse_dir(rows) == false then
            vim.notify("aborted, could not parse directory",vim.log.levels.ERROR)
            return
        end
        local _, _, fname = string.find(dimg.save_path, "([^/]+)$")
        if fname ~= nil and dimg.curr_listing[string.upper(fname)] ~= nil then
            local overwrite = vim.fn.input(string.upper(fname) .. " already exists, overwrite (y/n)? ")
            if overwrite == "y" or overwrite == "Y" then
                table.insert(dimg.pipeline,dimg.PUT)
                vim.lsp.buf.execute_command {
                    command = s .. ".disk.delete",
                    arguments = {
                        dimg.save_path
                    }
                }
            else
                vim.notify("aborted by user",vim.log.levels.INFO)
            end
        else
            put_func()
        end
    else
        vim.notify("action was interrupted by change in buffer",vim.log.levels.ERROR)
    end
end

---(async) Request directory or file from a disk image.
---Typically the handler needs a context, `ctx`, in order to act on the result.
---The `ctx` can be retrieved by using `table.remove` on `dimg.pipeline`.
function dimg.picker(curr_path,ctx)
    local s = dimg.get_server()
    if s ~= nil then
        dimg.curr_listing = {}
        if dimg.mounted[s] == nil then
            return
        end
        table.insert(dimg.pipeline,ctx)
        vim.lsp.buf.execute_command {
            command = s .. ".disk.pick",
            arguments = {
                curr_path,
                dimg.get_filter()
            }
        }
    else
        vim.notify("action was interrupted by change in buffer",vim.log.levels.ERROR)
    end
end

dimg.mount = {
    impl = function(args, opts)
        local s = dimg.get_server()
        if s == nil then
            vim.notify("buffer has the wrong filetype",vim.log.levels.ERROR)
            return
        end
        if #args ~= 1 then
            vim.notify("expected 1 arg, got " .. #args,vim.log.levels.ERROR)
            return
        end
        vim.lsp.buf.execute_command {
            command = s .. ".disk.mount",
            arguments = {
                vim.fs.normalize(args[1])
            }
        }
    end,
    complete = function (subcmd_arg_lead)
        local ans = {}
        local base = subcmd_arg_lead
        if subcmd_arg_lead:find("^~?/") == nil then
            base = "~/" .. base
        end
        base = string.gsub(base, "/[^/]*$", "/")
        for nm,typ in vim.fs.dir(vim.fs.normalize(base),{}) do
            local keep = typ == "directory"
            for _,filt in ipairs(dimg.file_filter) do
                keep = keep or string.find(string.lower(nm),"%."..filt.."$")~=nil
            end
            if keep then
                local proposed = base .. nm
                -- if typ == "directory" then
                --     proposed = proposed .. "/"
                -- end
                -- important to suppress magic characters (arg4=true)
                if string.find(proposed,subcmd_arg_lead,1,true)~=nil then
                    table.insert(ans,proposed)
                end
            end
        end
        return ans
    end
}

dimg.load = {
    impl = function(args, opts)
        local s = dimg.get_server()
        if s == nil then
            vim.notify("buffer has the wrong filetype", vim.log.levels.ERROR)
            return
        end
        if dimg.mounted[s] == nil then
            vim.notify("please mount a disk image first", vim.log.levels.ERROR)
            return
        end
        if #args ~= 1 then
            vim.notify("expected 1 arg, got " .. #args, vim.log.levels.ERROR)
            return
        end
        dimg.picker(args[1],dimg.LOAD)
    end,
    complete = function (subcmd_arg_lead)
        local ans = {}
        local base, matches = string.gsub(subcmd_arg_lead, "/[^/]*$", "/")
        if matches == 0 then
            base = ""
        end
        dimg.picker(base,dimg.COMP)
        -- wait a bit in hopes the server will fill the data.
        -- of course we should block until server is done, but how?
        vim.fn.wait(100,function() end)
        for nm,typ in pairs(dimg.curr_listing) do
            local proposed = base..nm
            -- important to suppress magic characters (arg4=true)
            if string.find(proposed,subcmd_arg_lead,1,true)~=nil then
                table.insert(ans,proposed)
            end
        end
        return ans
    end
}

dimg.save = {
    impl = function(args, opts)
        local s = dimg.get_server()
        if s == nil then
            vim.notify("buffer has the wrong filetype",vim.log.levels.ERROR)
            return
        end
        if dimg.mounted[s] == nil then
            vim.notify("please mount a disk image first", vim.log.levels.ERROR)
            return
        end
        if #args ~= 1 then
            vim.notify("expected 1 arg, got " .. #args,vim.log.levels.ERROR)
            return
        end
        if string.find(args[1],"\\") ~= nil then
            vim.notify("backslash is not allowed",vim.log.levels.ERROR)
            return
        end
        dimg.save_path = args[1]
        local base = ""
        if string.find(args[1],"/") ~= nil then
            base = string.gsub(args[1], "/[^/]*/?$", "")
        end
        dimg.picker(base,dimg.CHECK)
    end,
    complete = function (subcmd_arg_lead)
        local ans = {}
        local base, matches = string.gsub(subcmd_arg_lead, "/[^/]*$", "/")
        if matches == 0 then
            base = ""
        end
        dimg.picker(base,dimg.COMP)
        -- wait a bit in hopes the server will fill the data.
        -- of course we should block until server is done, but how?
        vim.fn.wait(100,function() end)
        for nm,typ in pairs(dimg.curr_listing) do
            local proposed = base..nm
            -- important to suppress magic characters (arg4=true)
            if string.find(proposed,subcmd_arg_lead,1,true)~=nil then
                table.insert(ans,proposed)
            end
        end
        return ans
    end
}

return dimg

