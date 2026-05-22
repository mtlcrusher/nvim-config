local map = vim.keymap.set

-- Clipboard helpers (existing)
map("v", "<leader>y", '"+y', { desc = "Yank to system clipboard" })
map("n", "<leader>yy", '"+yy', { desc = "Yank line to system clipboard" })
map("n", "<leader>pp", '"+p', { desc = "Paste from system clipboard" })

-- -------------------------
-- Verible helpers (only when tools exist)
-- -------------------------
-- <leader>vf : format current buffer (uses conform)
-- <leader>vl : lint current file (uses nvim-lint)
map("n", "<leader>vf", function()
  local ok, conform = pcall(require, "conform")
  if ok then
    conform.format({ async = false, lsp_fallback = true })
  else
    vim.notify("conform.nvim not available", vim.log.levels.WARN)
  end
end, { desc = "Format (Verible/Conform)" })

map("n", "<leader>vl", function()
  local ok, lint = pcall(require, "lint")
  if ok then
    lint.try_lint()
  else
    vim.notify("nvim-lint not available", vim.log.levels.WARN)
  end
end, { desc = "Lint (Verible/nvim-lint)" })
