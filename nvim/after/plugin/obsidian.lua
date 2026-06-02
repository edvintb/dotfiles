require("obsidian").setup({
    legacy_commands = false,
    workspaces = {
        {
            name = "vault",
            path = "~/vault",
        },
    },

    -- Completion now flows through the in-process `obsidian-ls` LSP; blink.cmp
    -- picks it up via the regular `lsp` source — no plugin-specific wiring.
    ui = { enable = false },
    notes_subdir = "",
    new_notes_location = "notes_subdir",

    ---@param title string|?
    ---@return string
    note_id_func = function(title)
        local suffix = ""
        if title ~= nil then
            suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
        else
            for _ = 1, 4 do
                suffix = suffix .. string.char(math.random(65, 90))
            end
        end
        return os.date("%Y%m%d%H%M") .. "-" .. suffix
    end,

    frontmatter = {
        ---@return table
        func = function(note)
            if note.title then
                note:add_alias(note.title)
            end

            local year = note.id:sub(1, 4)
            local month = note.id:sub(5, 6)
            local day = note.id:sub(7, 8)
            local hour = note.id:sub(9, 10)
            local minute = note.id:sub(11, 12)
            local cdate = string.format("%s-%s-%s %s:%s", year, month, day, hour, minute)

            local out = { id = note.id, cdate = cdate, aliases = note.aliases, tags = note.tags }

            if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
                for k, v in pairs(note.metadata) do
                    out[k] = v
                end
            end

            return out
        end,
    },
})

-- `gd` passthrough: open links under cursor in markdown buffers
vim.api.nvim_create_autocmd('FileType', {
    pattern = 'markdown',
    callback = function(ev)
        vim.keymap.set('n', 'gd', function()
            return require('obsidian').util.gf_passthrough()
        end, { buffer = ev.buf, expr = true, noremap = false, desc = 'obsidian gf passthrough' })
    end,
})

vim.keymap.set('n', '<leader>n', ':Obsidian new ', { noremap = true })
