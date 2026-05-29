require("nvchad.configs.lspconfig").defaults()

-- NvChad on Neovim 0.11+ / 0.12 uses the built-in LSP APIs.
-- Keep your existing generic servers and add a single SV LSP provider.
-- IMPORTANT: do not enable multiple SystemVerilog LSPs at the same time.

local servers = { "html", "cssls", "pyright", "clangd", "neocmake" }
vim.lsp.enable(servers)

local function has(bin)
  return vim.fn.executable(bin) == 1
end

local function find_sv_root(bufnr)
  local fname = vim.api.nvim_buf_get_name(bufnr)
  local root = vim.fs.root(fname, { ".svlangserver", ".git", "verible.filelist" })
  if root then
    return root
  end
  return vim.fs.dirname(fname)
end

local function create_once_user_command(name, rhs, opts)
  if vim.fn.exists(":" .. name) == 0 then
    vim.api.nvim_create_user_command(name, rhs, opts or {})
  end
end

-- -------------------------
-- Primary SV LSP: svlangserver
-- -------------------------
-- Why primary:
-- - workspace/module indexing
-- - better cross-file navigation for large RTL trees
-- - hierarchy reporting command
-- Keep Verible for formatting + linting through conform/nvim-lint.
if has("svlangserver") then
  local use_verilator = has("verilator")
  local use_iverilog = (not use_verilator) and has("iverilog")

  local launch_configuration
  local linter_name
  local disable_linting = true

  if use_verilator then
    linter_name = "verilator"
    launch_configuration = "verilator --sv --lint-only -Wall"
    disable_linting = false
  elseif use_iverilog then
    linter_name = "iverilog"
    launch_configuration = "iverilog -g2012 -t null"
    disable_linting = false
  else
    linter_name = "verilator"
    launch_configuration = "verilator --sv --lint-only -Wall"
    disable_linting = true
  end

  vim.lsp.config("svlangserver", {
    cmd = { "svlangserver" },
    filetypes = { "verilog", "systemverilog" },
    root_dir = function(bufnr, on_dir)
      on_dir(find_sv_root(bufnr))
    end,
    workspace_required = false,
    settings = {
      systemverilog = {
        includeIndexing = {
          "**/*.{v,vh,sv,svh}",
        },
        excludeIndexing = {
          "**/.git/**",
          "**/.jj/**",
          "**/build/**",
          "**/out/**",
          "**/dist/**",
          "**/obj_dir/**",
          "**/simv.daidir/**",
          "**/node_modules/**",
        },
        -- Files where module name != filename belong here.
        libraryIndexing = {
          "rtl/lib/**/*.{v,vh,sv,svh}",
          "ip/**/*.{v,vh,sv,svh}",
        },
        defines = {},
        linter = linter_name,
        launchConfiguration = launch_configuration,
        lintOnUnsaved = true,
        formatCommand = has("verible-verilog-format") == 1 and "verible-verilog-format" or "",
        disableLinting = disable_linting,
        disableCompletionProvider = false,
        disableHoverProvider = false,
        disableSignatureHelpProvider = false,
      },
    },
  })
  vim.lsp.enable("svlangserver")

  create_once_user_command("SvlangserverBuildIndex", function()
    local clients = vim.lsp.get_clients({ bufnr = 0, name = "svlangserver" })
    if #clients == 0 then
      vim.notify("svlangserver is not attached to the current buffer", vim.log.levels.WARN)
      return
    end
    vim.lsp.buf.execute_command({ command = "systemverilog.build_index" })
  end, { desc = "SVLangserver: rebuild workspace index" })

  create_once_user_command("SvlangserverReportHierarchy", function(_)
    local clients = vim.lsp.get_clients({ bufnr = 0, name = "svlangserver" })
    if #clients == 0 then
      vim.notify("svlangserver is not attached to the current buffer", vim.log.levels.WARN)
      return
    end
    vim.lsp.buf.execute_command({
      command = "systemverilog.report_hierarchy",
      arguments = { vim.fn.expand("<cword>") },
    })
  end, { desc = "SVLangserver: report hierarchy for symbol under cursor" })

-- -------------------------
-- Fallback SV LSP: Verible
-- -------------------------
elseif has("verible-verilog-ls") then
  vim.lsp.config("verible", {
    cmd = {
      "verible-verilog-ls",
      "--rules_config_search",
      "--lsp_enable_hover",
    },
    filetypes = { "verilog", "systemverilog" },
    root_markers = { "verible.filelist", ".rules.verible_lint", ".git" },
  })
  vim.lsp.enable("verible")
end

-- read :h vim.lsp.config for changing options of lsp servers
