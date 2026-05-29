# SVLangserver integration for this NvChad / Neovim 0.12 config

This update does three things:

1. Makes **`svlangserver`** the primary LSP for `verilog` / `systemverilog`.
2. Keeps **Verible** as formatter + linter via `conform.nvim` and `nvim-lint`.
3. Leaves `slang-server.nvim` only as a **last fallback** if `svlangserver` and Verible LSP are both unavailable.

## Why this layout?

- `svlangserver` is stronger for **workspace indexing**, **module/interface/package navigation**, and **hierarchy reporting**.
- Verible is still useful for **formatting** and **lint diagnostics**.
- Running more than one SV LSP at the same time usually creates duplicate diagnostics, duplicate completion items, and conflicting jumps.

## Install on UBI8 / RHEL8-family

### If you are on a standard or init UBI image

Use `yum` / `dnf` to add packages.

```bash
# examples; adapt to your image / entitlement situation
sudo yum install -y git curl unzip tar gcc-c++ make
sudo yum module list nodejs
sudo yum module reset -y nodejs
sudo yum module enable -y nodejs:18
sudo yum install -y nodejs npm
npm install -g @imc-trading/svlangserver
```

### If you are on UBI minimal

Use `microdnf` instead of `yum`.

```bash
microdnf install -y nodejs npm git curl tar gzip unzip
npm install -g @imc-trading/svlangserver
```

### Optional tools strongly recommended

```bash
# if available in your repos / image policy
sudo yum install -y verilator ripgrep
# verible is often installed from a separate internal toolchain or release archive
verilator --version
svlangserver --help
```

## Neovim behavior after this update

### LSP selection order

1. `svlangserver`
2. `verible-verilog-ls`
3. `slang-server`

Only the first available one is enabled for SV buffers.

### New keymaps

- `<leader>vb` → rebuild `svlangserver` index
- `<leader>vr` → generate hierarchy for symbol under cursor
- `<leader>vf` → format through Conform / Verible
- `<leader>vl` → lint through `nvim-lint` / Verible

### Project root detection

The SV project root is detected from the first of:

- `.svlangserver/`
- `.git/`
- `verible.filelist`

For best results, create a `.svlangserver/` directory in each RTL project root.

## Recommended project structure

```text
project/
├── .svlangserver/
├── include/
├── rtl/
│   ├── pkg/
│   ├── if/
│   ├── lib/
│   ├── core/
│   └── top/
├── tb/
├── verible.filelist
└── .rules.verible_lint
```

## Notes about settings

The `settings.systemverilog` block in `lua/configs/lspconfig.lua` is global-by-default and tuned for a large RTL tree.

You will likely want to edit these fields per environment:

- `libraryIndexing`
- `defines`
- `launchConfiguration`
- `excludeIndexing`

## Typical validation workflow

1. Open `rtl/top/soc_top.sv`
2. Run `:LspInfo` (or `:checkhealth vim.lsp`)
3. Confirm `svlangserver` is attached
4. Place cursor on `subsystem` and hit `gd`
5. Place cursor on `soc_top` and press `<leader>vr`
6. Press `<leader>vb` after changing file set / new modules
7. Press `<leader>vf` and `<leader>vl` to verify Verible integration
