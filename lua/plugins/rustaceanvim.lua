-- plugins/rustaceanvim.lua
-- rustaceanvim: better rust-analyzer defaults + inlay hints + DAP integration.
-- When this plugin loads, it:
--   * sets up rust-analyzer for us (so we no longer call vim.lsp.config()
--     for rust_analyzer directly — we keep configs/lspconfig.lua's block
--     guarded with `has("rust-analyzer") and not has_rustaceanvim()`).
--   * registers a "rust" DAP adapter backed by codelldb
--     and exposes `:RustLsp debuggables` to pick a target from cargo's output.
--
-- We pin to v6+ (the Lua-API rewrite) to guarantee `:RustLsp` commands.
return {
  {
    "mrcjkb/rustaceanvim",
    version = "^6", -- pin to v6+ API
    lazy = false, -- needed so rust-analyzer attaches on FileType rust
    init = function()
      -- rustaceanvim reads these from vim.g before nvim loads; set them here.
      vim.g.rustaceanvim = {
        dap = {
          -- Provide a full nvim-dap adapter spec (server type for codelldb).
          -- This mirrors what configs/dap.lua registers for codelldb.
          adapter = {
            type = "server",
            port = "${port}",
            executable = {
              command = vim.fn.exepath("codelldb") ~= "" and vim.fn.exepath("codelldb")
                or vim.fn.expand("~/.local/share/codelldb/adapter/codelldb"),
              args = { "--port", "${port}" },
              detached = false,
            },
          },
        },
        tools = {
          hover_actions = { auto_focus = true },
        },
        server = {
          default_settings = {
            ["rust-analyzer"] = {
              cargo = { allFeatures = true, loadOutDirsFromCheck = true },
              check = { command = "clippy" },
              procMacro = { enable = true },
              inlayHints = {
                chainingHints = true,
                closureCaptureHints = true,
                lifetimeElisionHints = { enable = "never" },
              },
            },
          },
        },
      }
    end,
    dependencies = {
      "mfussenegger/nvim-dap",
      "neovim/nvim-lspconfig",
    },
  },
}