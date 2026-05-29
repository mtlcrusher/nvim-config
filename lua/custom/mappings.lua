local map = vim.keymap.set

-- Clipboard helpers (existing)
map("v", "<leader>y", '"+y', { desc = "Yank to system clipboard" })
map("n", "<leader>yy", '"+yy', { desc = "Yank line to system clipboard" })
map("n", "<leader>pp", '"+p', { desc = "Paste from system clipboard" })

-- -------------------------
-- Verible helpers (existing)
-- -------------------------
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

-- -------------------------
-- SVLangserver helpers (new)
-- -------------------------
map("n", "<leader>vb", function()
  if vim.fn.exists(":SvlangserverBuildIndex") == 2 then
    vim.cmd("SvlangserverBuildIndex")
  else
    vim.notify("SvlangserverBuildIndex command not available", vim.log.levels.WARN)
  end
end, { desc = "SV: rebuild svlangserver index" })

map("n", "<leader>vr", function()
  if vim.fn.exists(":SvlangserverReportHierarchy") == 2 then
    vim.cmd("SvlangserverReportHierarchy")
  else
    vim.notify("SvlangserverReportHierarchy command not available", vim.log.levels.WARN)
  end
end, { desc = "SV: report hierarchy under cursor" })
