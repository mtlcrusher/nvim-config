local map = vim.keymap.set

map("v", "<leader>y", '"+y', { desc = "Yank to system clipboard" })
map("n", "<leader>yy", '"+yy', { desc = "Yank line to system clipboard" })
map("n", "<leader>p", '"+p', { desc = "Paste from system clipboard" })"})
