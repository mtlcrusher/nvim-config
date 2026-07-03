local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    rust = { "rustfmt" },
    -- css = { "prettier" },
    -- html = { "prettier" },
  },

  -- Custom formatter definitions.
  -- We register Verible formatter only when it's available in PATH.
  formatters = {},

  -- format_on_save = {
  --   -- These options will be passed to conform.format()
  --   timeout_ms = 500,
  --   lsp_fallback = true,
  -- },
}

-- -------------------------
-- Verible formatter (System)Verilog
-- -------------------------
-- Requires: verible-verilog-format in PATH.
if vim.fn.executable("verible-verilog-format") == 1 then
  options.formatters_by_ft.verilog = { "verible_format" }
  options.formatters_by_ft.systemverilog = { "verible_format" }

  options.formatters.verible_format = {
    command = "verible-verilog-format",
    stdin = true,
    -- Conform passes the buffer content on stdin.
    -- Verible uses '-' as stdin marker, and --stdin_name helps diagnostics.
    args = function(ctx)
      return {
        "--stdin_name",
        ctx.filename,
        "--column_limit=100",
        "-",
      }
    end,
  }
end

return options
