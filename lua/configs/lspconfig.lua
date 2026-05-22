require("nvchad.configs.lspconfig").defaults()

-- NvChad uses Neovim's built-in LSP enable() API.
-- Keep your existing servers and add Verible for (System)Verilog when available.
local servers = { "html", "cssls", "pyright", "clangd", "stylua", "neocmake" }
vim.lsp.enable(servers)

-- -------------------------
-- Verible LSP (System)Verilog
-- -------------------------
-- Requires these binaries in $PATH (e.g. Termux):
--   - verible-verilog-ls
-- Optional project files:
--   - verible.filelist        (project-wide symbols)
--   - .rules.verible_lint     (lint rules config)
--
-- If verible is present, enable it for verilog/systemverilog.
if vim.fn.executable("verible-verilog-ls") == 1 then
  vim.lsp.config("verible", {
    cmd = {
      "verible-verilog-ls",
      "--rules_config_search", -- auto-pick .rules.verible_lint by searching upward
      -- To force a different file list name:
      -- "--file_list_path", "verible.filelist",
    },
    filetypes = { "verilog", "systemverilog" },
    root_markers = { "verible.filelist", ".rules.verible_lint", ".git" },
  })

  vim.lsp.enable("verible")
end

-- read :h vim.lsp.config for changing options of lsp servers
