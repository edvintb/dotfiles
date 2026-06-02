-- blink.cmp config (replaces nvim-cmp + cmp-* + vim-vsnip).
-- LuaSnip + friendly-snippets still provide the snippet bodies.
require('luasnip.loaders.from_vscode').lazy_load()

require('blink.cmp').setup({
    keymap = {
        preset = 'none',
        ['<C-j>'] = { 'select_next', 'show' },
        ['<C-k>'] = { 'select_prev', 'show' },
        ['<C-y>'] = { 'accept', 'fallback' },
        ['<C-e>'] = { 'cancel', 'fallback' },
        ['<C-u>'] = { 'scroll_documentation_up', 'fallback' },
        ['<C-d>'] = { 'scroll_documentation_down', 'fallback' },
        ['<C-n>'] = { 'snippet_forward', 'fallback' },
        ['<C-p>'] = { 'snippet_backward', 'fallback' },
    },
    snippets = { preset = 'luasnip' },
    completion = {
        list = { selection = { preselect = true, auto_insert = false } },
        menu = {
            draw = {
                columns = { { 'kind_icon' }, { 'label', 'label_description', gap = 1 }, { 'source_name' } },
            },
        },
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
    },
    sources = {
        default = { 'lsp', 'snippets', 'buffer', 'path' },
        providers = {
            lsp = { min_keyword_length = 2 },
        },
    },
    signature = { enabled = true },
    fuzzy = { implementation = 'prefer_rust_with_warning' },
})
