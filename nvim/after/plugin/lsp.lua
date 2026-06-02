local wk = require("which-key")

-- LSP capabilities (snippets, completionItem.resolve, etc.) are contributed
-- automatically by blink.cmp into `vim.lsp.config('*')` — nothing to wire here.

vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(event)
        local opts = { buffer = event.buf, remap = false }
        vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, opts)
        vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, opts)
        vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
        vim.keymap.set("n", "gR", function() vim.lsp.buf.rename() end, opts)
        vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
        wk.add({
            { "gd", desc = "vim.lsp.buf.definition()" },
            { "gR", desc = "vim.lsp.buf.rename()" },
            { "[d", desc = "vim.diagnostic.jump prev" },
            { "]d", desc = "vim.diagnostic.jump next" },
        })
    end,
})

vim.lsp.config('rust_analyzer', {
    cmd = { 'rustup', 'run', 'stable', 'rust-analyzer' },
})

vim.lsp.config('ruff', {
    on_attach = function(client, bufnr)
        vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = bufnr,
            callback = function()
                if client:supports_method("textDocument/formatting") then
                    vim.lsp.buf.format({ bufnr = bufnr })
                else
                    vim.notify("Ruff formatter not available for this buffer.", vim.log.levels.WARN)
                end
            end,
        })
        vim.keymap.set('n', '<leader>lf', function()
            if client:supports_method("textDocument/formatting") then
                vim.lsp.buf.format()
            else
                vim.notify("Ruff formatter not available for this buffer.", vim.log.levels.WARN)
            end
        end, { buffer = bufnr, desc = '[L]sp [F]ormat' })
    end,
})

vim.lsp.config('pyright', {
    settings = {
        pyright = {
            disableOrganizeImports = true,
        },
        python = {
            analysis = {
                ignore = { '*' },
            },
        },
    },
})

-- Fix "Undefined global 'vim'" in neovim lua files (replaces lsp.nvim_workspace())
vim.lsp.config('lua_ls', {
    settings = {
        Lua = {
            runtime = { version = 'LuaJIT' },
            workspace = {
                checkThirdParty = false,
                library = { vim.env.VIMRUNTIME },
            },
        },
    },
})

vim.lsp.enable({ 'rust_analyzer', 'ruff', 'pyright', 'lua_ls' })

vim.keymap.set('n', '<leader>li', '<cmd>LspInfo<cr>')
vim.keymap.set('n', '<leader>ll', '<cmd>LspLog<cr>')
wk.add({
    { "<leader>li", desc = "LspInfo" },
    { "<leader>ll", desc = "LspLog" },
})
