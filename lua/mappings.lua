require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
-- map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

-- ─────────────────────────────────────────────────────────────────
-- Debugging (nvim-dap + nvim-dap-ui). The core continue/step/breakpoint
-- keys live in lua/plugins/dap.lua (so they don't load nvim-dap until used).
-- Here we keep only the UI-toggle key — it can safely be lazy because the
-- `require("dapui")` only resolves after nvim-dap has been loaded once.
-- ─────────────────────────────────────────────────────────────────
map("n", "<leader>dt", function()
  require("dapui").toggle { reset = true }
end, { desc = "DAP UI: toggle" })

-- Cursor-eval convenience: K to hover value when at a stopped breakpoint
-- (dapui's built-in `<leader>dh` covers this when UI is open).
map({ "n", "v" }, "<leader>dh", function()
  require("dap.ui.widgets").hover()
end, { desc = "DAP: Hover value" })

-- Visual-evaluate: send selected expression to dap repl
map("v", "<leader>de", function()
  require("dapui").eval()
end, { desc = "DAP: Evaluate selection" })

require("custom.mappings")
