-- Neovim 0.10+ ships native commenting at `gc` (operator) / `gcc` (line) /
-- `gbc` (block line). Replicate the previous Comment.nvim bindings.
vim.keymap.set('n', '<leader>cc', 'gcc', { remap = true, desc = 'Toggle line comment' })
vim.keymap.set('n', '<leader>bc', 'gbc', { remap = true, desc = 'Toggle block comment' })
vim.keymap.set({ 'n', 'x', 'o' }, '<leader>c', 'gc',  { remap = true, desc = 'Comment operator' })
vim.keymap.set({ 'n', 'x', 'o' }, '<leader>b', 'gb',  { remap = true, desc = 'Block comment operator' })
