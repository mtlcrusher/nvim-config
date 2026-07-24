-- plugins/rustaceanvim.lua
-- rustaceanvim: better rust-analyzer defaults + inlay hints + DAP integration.
-- When this plugin loads, it:
--   * sets up rust-analyzer for us (so we no longer call vim.lsp.config()
--     for rust_analyzer directly — we keep configs/lspconfig.lua's block
--     guarded with `has("rust-analyzer") and not has_rustaceanvim()`).
--   * registers a "rust" DAP adapter backed by codelldb (installed via Mason)
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
      -- codelldb is installed by mason-nvim-dap; rustaceanvim finds it
      -- automatically when `vim.g.rustaceanvim.dap.adapter` is "codelldb".
      vim.g.rustaceanvim = {
        -- defer config() until nvim-dap is loaded so require("dap") is in rtp
        dap = {
          adapter = "codelldb",
          -- autoload debug configs from cargo's build graph:
          -- `:RustLsp debuggables` shows tests/examples/binaries.
          configuration = function()
            -- rustaceanvim auto-generates this; the explicit function here
            -- only matters if you want to insert extra configs.
            return nil
          end,
        },
        tools = {
          -- float_win_opts = { border = "rounded" },
          hover_actions = { auto_focus = true },
        },
        server = {
          -- default_settings merged with rustaceanvim's "rust-analyzer" defaults
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
