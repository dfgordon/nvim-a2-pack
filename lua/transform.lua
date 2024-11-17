local xfrm = {}

local abas = require "applesoft"
local ibas = require "integerbasic"

xfrm.minify = {
    impl = function(args, opts)
        if #args > 1 then
            vim.notify("expected 0 or 1 args, got " .. #args, vim.log.levels.ERROR)
            return
        end
        local ft = vim.api.nvim_get_option_value('filetype', { buf = 0 })
        if ft ~= "applesoft" then
            vim.notify("can't minify " .. ft, vim.log.levels.ERROR)
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
}

xfrm.tokenize = {
    impl = function(args, opts)
        if #args > 1 then
            vim.notify("expected 0 or 1 args, got " .. #args, vim.log.levels.ERROR)
            return
        end
        local ft = vim.api.nvim_get_option_value('filetype', { buf = 0 })
        local arguments = {}
        if ft == "applesoft" then
            if #args > 0 then
                if abas.is_addr_bad(args[1]) then
                    return
                end
                abas.put_args.load_addr = tonumber(args[1])
            else
                abas.put_args.load_addr = tonumber(2049)
            end
            arguments = {
                vim.fn.join(vim.fn.getbufline(vim.fn.bufname("%"), 0, "$"), "\n"),
                abas.put_args.load_addr
            }
        elseif ft == "integerbasic" then
            if #args > 0 then
                ibas.load_addr = tonumber(args[1])
            else
                ibas.load_addr = tonumber(38400)
            end
            arguments = {
                vim.fn.join(vim.fn.getbufline(vim.fn.bufname("%"), 0, "$"), "\n")
            }
        else
            vim.notify("can't tokenize " .. ft, vim.log.levels.ERROR)
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
}

xfrm.renumber = {
    impl = function(args, opts)
        local ft = vim.api.nvim_get_option_value('filetype', { buf = 0 })
        if ft ~= "applesoft" and ft ~= "integerbasic" then
            vim.notify("can't renumber " .. ft, vim.log.levels.ERROR)
            return
        end
        if #args ~= 2 then
            vim.notify("expected 2 args, got " .. #args, vim.log.levels.ERROR)
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

xfrm.asm = {
    impl = function(args, opts)
        local ft = vim.api.nvim_get_option_value('filetype', { buf = 0 })
        if ft ~= "merlin" then
            vim.notify("can't assemble " .. ft, vim.log.levels.ERROR)
            return
        end
        if #args ~= 0 then
            vim.notify("expected 0 args, got " .. #args, vim.log.levels.ERROR)
            return
        end
        local rng = vim.lsp.util.make_given_range_params().range
        if rng['end'].line == -1 then
            vim.notify("spot assembler requires selection", vim.log.levels.ERROR)
            return
        end
        vim.lsp.buf.execute_command {
            command = "merlin6502.toData",
            arguments = {
                vim.fn.join(vim.fn.getbufline(vim.fn.bufname("%"), 0, "$"), "\n"),
                vim.uri_from_bufnr(0),
                rng.start.line,
                rng['end'].line+1
            }
        }
    end,
}

xfrm.dasm = {
    impl = function(args, opts)
        local ft = vim.api.nvim_get_option_value('filetype', { buf = 0 })
        if ft ~= "merlin" then
            vim.notify("can't disassemble " .. ft, vim.log.levels.ERROR)
            return
        end
        if #args ~= 0 then
            vim.notify("expected 0 args, got " .. #args, vim.log.levels.ERROR)
            return
        end
        local rng = vim.lsp.util.make_given_range_params().range
        if rng['end'].line == -1 then
            vim.notify("spot assembler requires selection", vim.log.levels.ERROR)
            return
        end
        vim.lsp.buf.execute_command {
            command = "merlin6502.toCode",
            arguments = {
                vim.fn.join(vim.fn.getbufline(vim.fn.bufname("%"), 0, "$"), "\n"),
                vim.uri_from_bufnr(0),
                rng.start.line,
                rng['end'].line+1
            }
        }
    end,
}

return xfrm