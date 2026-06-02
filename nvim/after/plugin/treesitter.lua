local ts = require('nvim-treesitter')

ts.setup({
    install_dir = vim.fn.stdpath('data') .. '/site',
})

ts.install({
    'bash', 'c', 'cpp', 'css', 'html', 'javascript', 'json', 'lua',
    'markdown', 'markdown_inline', 'python', 'query', 'rust', 'swift',
    'toml', 'tsx', 'typescript', 'vim', 'vimdoc', 'yaml',
})

-- Enable highlight/indent/fold for any buffer whose filetype has a parser
-- installed. pcall makes this a no-op when no parser exists, so any future
-- `:TSInstall <lang>` lights up automatically.
vim.api.nvim_create_autocmd('FileType', {
    callback = function(ev)
        if pcall(vim.treesitter.start, ev.buf) then
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
            vim.wo[0][0].foldmethod = 'expr'
        end
    end,
})

require'treesitter-context'.setup{
  enable = true,
  multiwindow = false,
  max_lines = 4,
  min_window_height = 0,
  line_numbers = true,
  multiline_threshold = 2,
  trim_scope = 'outer',
  mode = 'cursor',
  separator = nil,
  zindex = 20,
  on_attach = nil,
}
