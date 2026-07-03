return {
  -- Primary Rust LSP + tooling
  {
    "mrcjkb/rustaceanvim",
    version = "^6",
    lazy = false, -- load early so LSP attaches on first Rust buffer
    config = function()
      local ok, rustaceanvim = pcall(require, "rustaceanvim.config.internal")
      if ok then
        -- Use vim.lsp.config / vim.lsp.enable path (Neovim 0.11+).
        -- The NvChad pattern activates LSP servers declaratively through
        -- lspconfig.lua. For Rust, rustaceanvim takes ownership of
        -- rust-analyzer setup and registers the server.
        --
        -- Key defaults that matter:
        --   tools.inlay_hints.auto = false by default; enable below.
        --   server.default_settings sets rust-analyzer config.
      end

      vim.g.rustaceanvim = {
        tools = {
          -- Show inlay hints (type annotations, param names) automatically
          inlay_hints = {
            auto = true,
            show_parameter_hints = false,
            only_current_line = false,
          },
          -- Hover actions (clickable links in hover window)
          hover_actions = {
            auto_focus = true,
            border = "rounded",
          },
          -- Code lens (references, debug, runnables)
          code_lens = {
            enabled = true,
            -- "Debug" is not useful without DAP wired up
            -- "Implementations" adds noise; references from lspconfig is enough
            disabled = { "Debug", "Implementations" },
          },
          -- Runnable icons (▶) in the sign column
          runnables = {
            use_telescope = true,
          },
        },

        server = {
          -- Match the activation pattern used in lspconfig.lua: use
          -- vim.lsp.config + vim.lsp.enable with NvChad.
          -- rustaceanvim auto-registers rust-analyzer via that API on 0.11+ when
          -- it detects the server is not already configured.
          default_settings = {
            -- rust-analyzer settings
            ["rust-analyzer"] = {
              cargo = {
                allFeatures = false,
                noDefaultFeatures = false,
                features = {},
              },
              check = {
                command = "check",
                overrideCommand = nil, -- let rust-analyzer manage it
                extraArgs = {},
              },
              diagnostics = {
                disabled = { "unresolved-proc-macro" },
                enable = true,
              },
              inlayHints = {
                -- rustaceanvim.tools.inlay_hints drives display;
                -- these control what rust-analyzer computes.
                typeHints = { enable = true },
                parameterHints = { enable = false },
                chainingHints = { enable = true },
                closureReturnTypeHints = { enable = "always" },
                lifetimeElisionHints = { enable = "never" },
              },
              procMacro = {
                enable = true,
              },
            },
          },
        },

        dap = {
          -- DAP not configured yet (no codelldb in Termux).
          -- Keep config stub so plugin doesn't error.
          adapter = {
            get_args = function()
              return {}
            end,
          },
        },
      }
    end,
  },

  -- Cargo.toml version management
  {
    "saecki/crates.nvim",
    event = { "BufRead Cargo.toml", "BufNewFile Cargo.toml" },
    config = true,
  },
}