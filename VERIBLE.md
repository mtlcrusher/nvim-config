# Verible integration (added)

This config enables Verible tools for Verilog/SystemVerilog when the binaries are found in `$PATH`:

- LSP: `verible-verilog-ls`
- Formatter: `verible-verilog-format` (via conform.nvim)
- Linter: `verible-verilog-lint` (via nvim-lint)

## Recommended project files

- `verible.filelist` (project-wide symbol discovery). Generate in project root:

  ```sh
  find . -name "*.sv" -o -name "*.svh" -o -name "*.v" | sort > verible.filelist
  ```

- `.rules.verible_lint` (lint rules config). With `--rules_config_search`, Verible searches upward for this file.

## Keymaps

- `<leader>vf` : format current buffer
- `<leader>vl` : lint current file
