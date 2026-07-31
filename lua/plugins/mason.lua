-- plugins/mason.lua
-- Mason: install + auto-configure external tooling (LSP servers, formatters,
-- linters, DAP adapters). Loaded eagerly (lazy = false) so tool installs are
-- guaranteed available before FileType-driven LSP/dap setup boots.
--
-- DAP adapter list:
--   python   -> debugpy    (Python)
--   codelldb -> lldb-based DAP, used for C/C++ AND Rust
--   gdb      -> multiarch-enabled gdb with --interpreter=dap, used for
--               remote-attach to cross-compiled RISC-V/ARM firmware images
return {
  {
    "williamboman/mason.nvim",
    lazy = false,
    config = function()
      require("mason").setup {
        ui = {
          border = "rounded",
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        },
      }
    end,
  },

  -- Auto-install missing tools on startup (idempotent; only installs if absent)
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "williamboman/mason.nvim" },
    lazy = false,
    config = function()
      require("mason-tool-installer").setup {
        ensure_installed = {
          -- DAP adapters live in mason-nvim-dap's ensure_installed below;
          -- we keep them out of mason-tool-installer to avoid duplicates.
          -- Add tooling like linters/formatters here as needed:
          -- "ruff", "clang-format", "codelldb",
        },
        auto_update = false,
        run_on_start = true,
      }
    end,
  },

  -- mason-nvim-dap: register Mason-installed adapters with nvim-dap
  -- and auto-install the ones we list. This is the canonical bridge between
  -- Mason and nvim-dap and avoids us hardcoding paths under
  -- ~/.local/share/nvim/mason/packages/<adapter>/bin/<adapter>.
  {
    "jay-babu/mason-nvim-dap.nvim",
    lazy = false,
    dependencies = {
      "williamboman/mason.nvim",
      "mfussenegger/nvim-dap",
    },
    config = function()
      require("mason-nvim-dap").setup {
        -- `ensure_installed` here installs DAP adapter packages AND triggers
        -- the auto-config handlers below (unless `handlers = {}`).
        ensure_installed = {
          "python",   -- debugpy
          -- "codelldb" -- lldb-based, C/C++ and Rust (installed manually at ~/.local/share/codelldb/)
        },
        -- Skip mason-nvim-dap's own auto-config for codelldb: our configs/dap.lua
        -- defines a more robust codelldb executable resolver (Mason path with
        -- system PATH fallback) plus per-language launch configs.
        -- `handlers = {}` => only install, don't auto-call dap.adapters[name]=...
        handlers = {
          -- python: register the debugpy adapter ourselves instead of relying
          -- on mason-nvim-dap's built-in handler, so the adapter path is
          -- explicit and easy to override further in configs/dap.lua.
          python = function()
            local dap = require "dap"
            dap.adapters.python = {
              type = "executable",
              command = (vim.fn.exepath "python3" ~= "" and vim.fn.exepath "python3")
                or (vim.fn.exepath "python" ~= "" and vim.fn.exepath "python")
                or "python3",
              args = { "-m", "debugpy.adapter" },
              options = { source_file_type = "python" },
            }
            -- configurations are filled in by configs/dap.lua
          end,

          -- Skip mason-nvim-dap's codelldb registration; ours is more complete.
          codelldb = function() end,
        },
        automatic_installation = true,
      }
    end,
  },
}
