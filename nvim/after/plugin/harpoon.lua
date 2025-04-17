local harpoon = require("harpoon")

harpoon:setup({
    global_settings = {
        mark_branch = true,
    }
})

vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end)
vim.keymap.set("n", "<leader>h", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

-- Use Alt+[1-4] instead of Ctrl+hjkl
vim.keymap.set("n", "<A-1>", function() harpoon:list():select(1) end)
vim.keymap.set("n", "<A-2>", function() harpoon:list():select(2) end)
vim.keymap.set("n", "<A-3>", function() harpoon:list():select(3) end)
vim.keymap.set("n", "<A-4>", function() harpoon:list():select(4) end)

-- map C-<number> via kitty remap to S-F<number>
vim.keymap.set("n", "<S-F1>", function() harpoon:list():select(1) end)
vim.keymap.set("n", "<S-F2>", function() harpoon:list():select(2) end)
vim.keymap.set("n", "<S-F3>", function() harpoon:list():select(3) end)
vim.keymap.set("n", "<S-F4>", function() harpoon:list():select(4) end)
vim.keymap.set("n", "<S-F5>", function() harpoon:list():select(5) end)
vim.keymap.set("n", "<S-F6>", function() harpoon:list():select(6) end)
vim.keymap.set("n", "<S-F7>", function() harpoon:list():select(7) end)
vim.keymap.set("n", "<S-F8>", function() harpoon:list():select(8) end)
vim.keymap.set("n", "<S-F9>", function() harpoon:list():select(9) end)
vim.keymap.set("n", "<S-F10>", function() harpoon:list():select(10) end)

