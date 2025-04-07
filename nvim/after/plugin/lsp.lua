local lsp = require('lsp-zero')
local wk = require("which-key")

require('luasnip.loaders.from_vscode').lazy_load()

lsp.preset({
    name = 'recommended',
    set_lsp_keymaps = {
        omit = {'gr'},
    },
    manage_nvim_cmp = {
        set_sources = false,
        set_basic_mappings = false,
        set_extra_mappings = false,
        use_luasnip = true,
    }
})

lsp.on_attach(function(client, bufnr)
    -- https://github.com/ThePrimeagen/init.lua/blob/after/plugin/lsp.lua
    local opts = {buffer = bufnr, remap = false}
    vim.keymap.set("n", "[d", function() vim.diagnostic.goto_prev() end, opts)
    vim.keymap.set("n", "]d", function() vim.diagnostic.goto_next() end, opts)
    vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
    vim.keymap.set("n", "gR", function() vim.lsp.buf.rename() end, opts)
    vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
    wk.add(
        {
            { "gd", desc = "vim.lsp.buf.definition()" },
            { "gR", desc = "vim.lsp.buf.rename()" },
            { "[d", desc = "vim.diagnostic.goto_prev()" },
            { "]d", desc = "vim.diagnostic.goto_next()" },
        }
    )
end)

lsp.nvim_workspace() -- Fix Undefined global 'vim'
lsp.skip_server_setup({'jdtls'})
lsp.setup()

vim.keymap.set('n', '<leader>li', '<cmd>LspInfo<cr>')
vim.keymap.set('n', '<leader>ll', '<cmd>LspLog<cr>')
wk.add(
  {
    { "<leader>li", desc = "LspInfo" },
    { "<leader>ll", desc = "LspLog" },
  }
)
-- TODO: should this be somewhere else?
-- rust setup
require('lspconfig').rust_analyzer.setup({
    cmd = {
        'rustup', 'run', 'stable', 'rust-analyzer',
    },
})

require('lspconfig').ruff.setup {
  -- Your other ruff_lsp configurations here

  capabilities = require('cmp_nvim_lsp').default_capabilities(),

  on_attach = function(client, bufnr)
    -- Format on Save (Conditional)
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      callback = function()
        if client.supports_method("textDocument/formatting") then
          vim.lsp.buf.format({ bufnr = bufnr })
        else
          vim.notify("Ruff formatter not available for this buffer.", vim.log.levels.WARN)
        end
      end,
    })

    -- Keybinding to Format (Conditional)
    vim.keymap.set('n', '<leader>lf', function()
      if client.supports_method("textDocument/formatting") then
        vim.lsp.buf.format()
      else
        vim.notify("Ruff formatter not available for this buffer.", vim.log.levels.WARN)
      end
    end, { buffer = bufnr, desc = '[L]sp [F]ormat' })

    -- Your other on_attach configurations here
  end,
}

require('lspconfig').pyright.setup {
  settings = {
    pyright = {
      -- Using Ruff's import organizer
      disableOrganizeImports = true,
    },
    python = {
      analysis = {
        -- Ignore all files for analysis to exclusively use Ruff for linting
        ignore = { '*' },
      },
    },
  },
}
