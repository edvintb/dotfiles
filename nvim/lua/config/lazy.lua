require("config.set")
require("config.remap")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    -- plugins

    { 'Shatur/neovim-ayu' },
    { 'catppuccin/nvim' },
    { 'rebelot/kanagawa.nvim' },
    { 'sainnhe/gruvbox-material' },
    { 'navarasu/onedark.nvim' },
    { 'rose-pine/neovim' },

    { 'nvim-lualine/lualine.nvim' },

    -- ai assistant
    {
        'augmentcode/augment.vim',
        branch = "prerelease",
        version = false,
    },

    {
        'nvim-telescope/telescope.nvim',
        dependencies = { 'nvim-lua/plenary.nvim' },
    },
    {
        'nvim-treesitter/nvim-treesitter',
        dependencies = {
            'nvim-treesitter/nvim-treesitter-textobjects',
        },
        build = ':TSUpdate',
    },
    { 'nvim-treesitter/nvim-treesitter-context' },
    { 'nvim-tree/nvim-web-devicons' },

    {
        'ThePrimeagen/harpoon',
        branch = "harpoon2",
        dependencies = { "nvim-lua/plenary.nvim" },
    },
    { 'tpope/vim-surround' },
    { 'tpope/vim-fugitive' },
    { 'tpope/vim-rhubarb' },
    { 'mbbill/undotree' },
    { 'lewis6991/gitsigns.nvim' },
    { "numToStr/Comment.nvim" },
    -- { "lukas-reineke/indent-blankline.nvim" },
    { "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} },
    {
        'folke/trouble.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        opts = {
            padding = false,
        },
    },
    {
        'folke/todo-comments.nvim',
        dependencies = { 'nvim-lua/plenary.nvim' },
    },
    {
        'folke/which-key.nvim',
        event = 'VeryLazy',
        init = function()
            vim.o.timeout = true
            vim.o.timeoutlen = 1000
        end,
        opts = {
            triggers_nowait = {},  -- disable showing marks instantly
        }
    },
    {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v2.x',
        dependencies = {
            -- lsp
            {
                'neovim/nvim-lspconfig'  -- Required
            },
            {                                      -- Optional
                'williamboman/mason.nvim',
                build = function()
                    pcall(vim.cmd, 'MasonUpdate')
                end,
            },
            {'williamboman/mason-lspconfig.nvim'}, -- Optional
            -- autocomplete
            {'hrsh7th/nvim-cmp'},     -- Required
            {'hrsh7th/cmp-nvim-lsp'}, -- Required
            {'L3MON4D3/LuaSnip'},     -- Required
            { 'hrsh7th/cmp-buffer' },
            { 'hrsh7th/cmp-path' },
            { 'hrsh7th/cmp-vsnip' },
            { 'hrsh7th/vim-vsnip' },
            { 'hrsh7th/cmp-nvim-lsp-signature-help' },
            { 'saadparwaiz1/cmp_luasnip' },
            { "rafamadriz/friendly-snippets" }
        }
    },
    -- language-specific plugins
    { 'mfussenegger/nvim-jdtls' },
    -- { 'simrat39/rust-tools.nvim' },

    { "aserowy/tmux.nvim" },
    {
        'stevearc/oil.nvim',
        opts = {},
        -- Optional dependencies
        dependencies = { "nvim-tree/nvim-web-devicons" },
    },

    { 'lervag/vimtex' },

    { 'eandrju/cellular-automaton.nvim' },

    {
        "epwalsh/obsidian.nvim",
        version = "*",  -- recommended, use latest release instead of latest commit
        lazy = true,
        ft = "markdown",
        dependencies = { "nvim-lua/plenary.nvim" },
    },
}, {
    -- options
    -- rocks = {
    --     hererocks = true,  -- recommended if you do not have global installation of Lua 5.1.
    -- },

    defaults = {
        lazy = false,
        version = false,
    },
})

--     {
--         "benlubas/molten-nvim",
--         dependencies = { "3rd/image.nvim" },
--         build = ":UpdateRemotePlugins",
--         init = function()
--             -- I find auto open annoying, keep in mind setting this option will require setting
--             -- a keybind for `:noautocmd MoltenEnterOutput` to open the output again
--             vim.g.molten_auto_open_output = false
-- 
--             -- this guide will be using image.nvim
--             -- Don't forget to setup and install the plugin if you want to view image outputs
--             vim.g.molten_image_provider = "image.nvim"
-- 
--             -- optional, I like wrapping. works for virt text and the output window
--             vim.g.molten_wrap_output = true
-- 
--             -- Output as virtual text. Allows outputs to always be shown, works with images, but can
--             -- be buggy with longer images
--             vim.g.molten_virt_text_output = true
-- 
--             -- this will make it so the output shows up below the \`\`\` cell delimiter
--             vim.g.molten_virt_lines_off_by_1 = true
-- 
--             vim.keymap.set("n", "<localleader>e", ":MoltenEvaluateOperator<CR>", { desc = "evaluate operator", silent = true })
--             vim.keymap.set("n", "<localleader>os", ":noautocmd MoltenEnterOutput<CR>", { desc = "open output window", silent = true })
--         end,
--     },
--     {
--         "3rd/image.nvim",
--         opts = {
--             -- options from the not-so-quick-start guide for the molten plugin
--             backend = "kitty", -- whatever backend you would like to use
--             max_width = 100,
--             max_height = 12,
--             max_height_window_percentage = math.huge,
--             max_width_window_percentage = math.huge,
--             window_overlap_clear_enabled = true, -- toggles images when windows are overlapped
--             window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
--         }
--     },
