local lint = require("lint")

-- Configure Verible linter for Verilog/SystemVerilog.
-- Requires: verible-verilog-lint in PATH.
--
-- nvim-lint requires a `parser` for custom linters. Without it, you'll see errors like:
--   attempt to index local 'parser' (a nil value)
--
-- This parser matches typical verible output:
--   path/to/file.sv:LINE:COL: message [Style: ...][rule]
--
if vim.fn.executable("verible-verilog-lint") == 1 then
  lint.linters_by_ft = lint.linters_by_ft or {}
  lint.linters_by_ft.verilog = { "verible_lint" }
  lint.linters_by_ft.systemverilog = { "verible_lint" }

  local parser = require("lint.parser").from_pattern(
    "([^:]+):(%d+):(%d+):%s*(.+)",
    { "file", "lnum", "col", "message" },
    {},
    { source = "verible-verilog-lint" }
  )

  lint.linters.verible_lint = {
    cmd = "verible-verilog-lint",
    stdin = false,
    append_fname = true,
    args = {
      "--rules_config_search", -- searches for .rules.verible_lint upward
      "--lint_fatal=false",
      "--parse_fatal=false",
    },
    stream = "stdout",
    parser = parser,
  }

  -- Lint on save / enter / insert leave
  vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter", "InsertLeave" }, {
    pattern = { "*.v", "*.sv", "*.svh" },
    callback = function()
      lint.try_lint()
    end,
  })
end
