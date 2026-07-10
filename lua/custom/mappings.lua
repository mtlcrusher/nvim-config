-- custom/mappings.lua — minimal, non-conflicting overrides
-- All NvChad default keymaps are preserved; only add needed extras here
local map = vim.keymap.set

-- Clipboard helpers
map("v", "<leader>y", '"+y', { desc = "Yank to system clipboard" })
map("n", "<leader>yy", '"+yy', { desc = "Yank line to system clipboard" })
map("n", "<leader>pp", '"+p', { desc = "Paste from system clipboard" })