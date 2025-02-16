local wk = require('which-key')

local opts = { silent = true, noremap = true }

vim.keymap.set("n", "<leader>xx", function() require("trouble").toggle() end, opts)
vim.keymap.set("n", "<leader>xw", function() require("trouble").open("workspace_diagnostics") end, opts)
vim.keymap.set("n", "<leader>xd", function() require("trouble").open("document_diagnostics") end, opts)
vim.keymap.set("n", "<leader>xq", function() require("trouble").open("quickfix") end, opts)
vim.keymap.set("n", "<leader>xl", function() require("trouble").open("loclist") end, opts)
vim.keymap.set("n", "gr", function() require("trouble").open("lsp_references") end, opts)
wk.add(
  {
    { "<leader>xd", desc = "trouble.open(document_diagnostics)" },
    { "<leader>xl", desc = "trouble.open(loclist)" },
    { "<leader>xq", desc = "trouble.open(quickfix)" },
    { "<leader>xw", desc = "trouble.open(workspace_diagnostics)" },
    { "<leader>xx", desc = "trouble.toggle()" },
  }
)
wk.add(
  {
    { "gr", desc = "trouble.open(lsp_references)" },
  }
)
