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

-- -------------------------
-- Rust helpers
-- -------------------------
-- rustaceanvim keymaps (these shadow LSP defaults that rustaceanvim overrides)
map("n", "K", function()
  local ok, rustaceanvim = pcall(require, "rustaceanvim.hover_actions")
  if ok then
    rustaceanvim.hover_actions.hover_actions()
  else
    vim.lsp.buf.hover()
  end
end, { desc = "Rust hover actions" })

map("n", "<leader>rr", function()
  local ok, cmd = pcall(require, "rustaceanvim.commands")
  if ok then
    cmd.runnables()
  else
    vim.notify("rustaceanvim not available", vim.log.levels.WARN)
  end
end, { desc = "Rust: list runnables" })

map("n", "<leader>re", function()
  local ok, cmd = pcall(require, "rustaceanvim.commands")
  if ok then
    cmd.expand_macro()
  else
    vim.notify("rustaceanvim not available", vim.log.levels.WARN)
  end
end, { desc = "Rust: expand macro under cursor" })

map("n", "<leader>ri", function()
  local ok, toggle = pcall(require, "rustaceanvim.inlay_hints")
  if ok then
    toggle.toggle_inlay_hints()
  else
    vim.notify("rustaceanvim not available", vim.log.levels.WARN)
  end
end, { desc = "Rust: toggle inlay hints" })

map("n", "<leader>rd", function()
  local ok, debuggables = pcall(require, "rustaceanvim.commands")
  if ok then
    debuggables.debuggables()
  else
    vim.notify("rustaceanvim not available", vim.log.levels.WARN)
  end
end, { desc = "Rust: list debuggables" })
