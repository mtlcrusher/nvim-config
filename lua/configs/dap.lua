-- configs/dap.lua
-- Central nvim-dap configuration: adapters + per-language launch configs.
-- Languages covered: Python (debugpy), C/C++ (codelldb / gdb) — including
-- embedded cross targets (RISC-V, ARM) — and Rust (rustaceanvim via codelldb).
--
-- Design notes:
--   * mason-nvim-dap installs and registers the adapter binaries; we only
--     override what that auto-config gets wrong (e.g. pointing codelldb at a
--     known NDK lldb when available).
--   * Per-language configurations choose the adapter by name, so swapping
--     the underlying binary later (Mason vs system vs NDK) is one line.
--   * Cross-compile targets are first-class: a "c_cpp_attach" pick list lets
--     you attach to a remote gdbserver for firmware; a "c_cpp_launch" config
--     runs the native binary under codelldb for host-compiled tests/examples.

local M = {}

local function has_module(p)
  local ok, m = pcall(require, p)
  return ok and m or nil
end

function M.setup()
  local dap = require "dap"
  local dapui = require "dapui"

  -- ──────────────────────────────────────────────────────────────────
  -- UI: dap-ui + virtual-text
  -- ──────────────────────────────────────────────────────────────────
  dapui.setup {
    layouts = {
      {
        elements = {
          { id = "scopes",      size = 0.30 },
          { id = "variables",   size = 0.30 },
          { id = "breakpoints", size = 0.20 },
          { id = "watches",     size = 0.20 },
        },
        size = 0.35,
        position = "left",
      },
      {
        elements = {
          { id = "repl",    size = 0.40 },
          { id = "console", size = 0.30 },
          { id = "stacks",  size = 0.30 },
        },
        size = 0.30,
        position = "bottom",
      },
    },
    controls = { enabled = true, element = "repl" },
    render = { max_type_length = nil, max_value_lines = 100 },
  }

  local vtext = has_module "nvim-dap-virtual-text"
  if vtext then
    vtext.setup {
      enabled = true,
      enabled_commands = true,
      highlight_changed_variables = true,
      highlight_new_as_changed = true,
      all_frames = false,
      commented = false,
      only_last_definition = true,
      filter_references_pattern = "",
    }
  end

  -- ──────────────────────────────────────────────────────────────────
  -- Signs
  -- ──────────────────────────────────────────────────────────────────
  vim.fn.sign_define("DapBreakpoint", {
    text = "",
    texthl = "DiagnosticSignError",
    linehl = "",
    numhl = "",
  })
  vim.fn.sign_define("DapBreakpointCondition", {
    text = "",
    texthl = "DiagnosticSignWarn",
    linehl = "",
    numhl = "",
  })
  vim.fn.sign_define("DapBreakpointRejected", {
    text = "",
    texthl = "DiagnosticSignHint",
    linehl = "",
    numhl = "",
  })
  vim.fn.sign_define("DapStopped", {
    text = "",
    texthl = "DiagnosticSignInfo",
    linehl = "DapStoppedLine",
    numhl = "DapStoppedLine",
  })

  -- Auto-open/close dap-ui on session start/terminated
  dap.listeners.after.event_initialized.dapui = function()
    dapui.open { reset = true }
  end
  dap.listeners.before.event_terminated.dapui = function()
    dapui.close()
  end
  dap.listeners.before.event_exited.dapui = function()
    dapui.close()
  end

  -- ──────────────────────────────────────────────────────────────────
  -- Adapter resolution
  --   Prefer codelldb (installed via mason-nvim-dap). If a known NDK lldb
  --   is present, override the command so we get the matching MI protocol
  --   version for Android-target binaries.
  -- ──────────────────────────────────────────────────────────────────
  -- codelldb adapter (used for C/C++ AND Rust by default)
  -- mason-nvim-dap already registers "codelldb"; we override only the server
  -- port auto-selection to avoid clashes when running multiple nvim sessions.
  dap.adapters.codelldb = {
    type = "server",
    port = "${port}",
    executable = function()
      -- Find the codelldb binary Mason installed (fall back to PATH)
      local mason_registry = has_module "mason-registry"
      local codelldb_path
      if mason_registry then
        local ok, pkg = pcall(function()
          return require("mason-registry").get_package "codelldb"
        end)
        if ok and pkg and pkg:is_installed() then
          codelldb_path = pkg:get_install_path() .. "/extension/adapter/codelldb"
        end
      end
      if not codelldb_path or codelldb_path == "" then
        local fallback = vim.fn.exepath "codelldb"
        codelldb_path = fallback ~= "" and fallback or "codelldb"
      end
      return {
        command = codelldb_path,
        args = { "--port", "${port}" },
        detached = false,
      }
    end,
  }

  -- gdb adapter — used as a fallback for cross-compiled RISC-V/ARM firmware
  -- when launching under a remote gdbserver. mason-nvim-dap also registers
  -- "gdb" if the gdb package is installed; we keep a system-gdb fallback so
  -- a multiarch gdb at /usr/bin/gdb works out of the box.
  if not dap.adapters.gdb then
    dap.adapters.gdb = {
      type = "executable",
      command = "gdb",
      args = { "--interpreter=dap" },
    }
  end

  -- ──────────────────────────────────────────────────────────────────
  -- Per-language configurations
  -- ──────────────────────────────────────────────────────────────────

  --  Python ──────────────────────────────────────────────────────────
  --  mason-nvim-dap registers debugpy under adapter name "python"; we wire
  --  two configs: launch current file, and launch with args (asks user).
  dap.configurations.python = {
    {
      type = "python",
      request = "launch",
      name = "Python: Current file",
      program = "${file}",
      cwd = "${workspaceFolder}",
      justMyCode = true,
      console = "integratedTerminal",
    },
    {
      type = "python",
      request = "launch",
      name = "Python: Current file (justMyCode=false)",
      program = "${file}",
      cwd = "${workspaceFolder}",
      justMyCode = false,
      console = "integratedTerminal",
    },
    {
      type = "python",
      request = "launch",
      name = "Python: Module (-m)",
      module = function()
        return vim.fn.input "Module: "
      end,
      cwd = "${workspaceFolder}",
      justMyCode = true,
      console = "integratedTerminal",
    },
    {
      type = "python",
      request = "attach",
      name = "Python: Attach (debugpy 5678)",
      connect = { host = "127.0.0.1", port = 5678 },
      justMyCode = false,
      pathMappings = {
        { localRoot = "${workspaceFolder}", remoteRoot = "." },
      },
    },
  }

  --  C / C++  ───────────────────────────────────────────────────────
  --  Two families:
  --    1. Launch host-compiled binaries (test exes, examples, host runs)
  --    2. Attach to a remote gdbserver for cross-compiled embedded targets
  --       (RISCV / ARM). Uses codelldb's remote-attach model with an
  --       initCommands file preloaded if present.
  --
  --  The user is prompted for the binary path and (for attach) the
  --  gdbserver host:port. The default 127.0.0.1:3333 matches common
  --  OpenOCD / J-Link / QEMU setups.
  dap.configurations.c = {
    {
      type = "codelldb",
      request = "launch",
      name = "C/C++: Launch binary (codelldb)",
      program = function()
        return vim.fn.input("Binary: ", vim.fn.expand "%:p:h" .. "/", "file")
      end,
      cwd = "${workspaceFolder}",
      stopOnEntry = false,
      args = function()
        local a = vim.fn.input "Args (space-separated, blank=none): "
        if a == "" then
          return {}
        end
        return vim.split(a, " ", { trimempty = true })
      end,
      runInTerminal = true,
      console = "integratedTerminal",
    },
    {
      type = "codelldb",
      request = "attach",
      name = "C/C++: Attach remote (gdbserver 127.0.0.1:3333)",
      program = function()
        return vim.fn.input("Binary (with symbols): ", vim.fn.expand "%:p:h" .. "/", "file")
      end,
      cwd = "${workspaceFolder}",
      initCommands = function()
        -- If a .gdbinit exists at workspaceFolder, source it (common for
        -- target-specific python-gdb scripts / cache disable / etc).
        local init = vim.fn.findfile(".gdbinit", vim.fn.getcwd() .. ";")
        return init ~= "" and { "command source " .. init } or {}
      end,
      sourceLanguages = { "c", "cpp", "rust" },
      -- codelldb remote attach: tell it to connect over gdb_remote.
      gdbRemote = {
        host = function()
          return vim.fn.input("Host: ", "127.0.0.1")
        end,
        port = function()
          local p = vim.fn.input("Port: ", "3333")
          return tonumber(p) or 3333
        end,
      },
    },
    {
      type = "gdb",
      request = "launch",
      name = "C/C++: Launch binary (gdb)",
      program = function()
        return vim.fn.input("Binary: ", vim.fn.expand "%:p:h" .. "/", "file")
      end,
      cwd = "${workspaceFolder}",
      stopOnEntry = false,
      args = function()
        local a = vim.fn.input "Args (space-separated, blank=none): "
        if a == "" then
          return {}
        end
        return vim.split(a, " ", { trimempty = true })
      end,
    },
  }

  -- cpp inherits from c
  dap.configurations.cpp = dap.configurations.c

  --  Rust ────────────────────────────────────────────────────────────
  --  rustaceanvim owns the Rust DAP adapter registration when loaded, so
  --  this fallback is only used when rustaceanvim is disabled or unavailable.
  --  rustaceanvim injects configs on FileType rust; ours acts as a backstop.
  dap.configurations.rust = dap.configurations.rust or {
    {
      type = "codelldb",
      request = "launch",
      name = "Rust: launch (fallback, prefer rustaceanvim)",
      program = function()
        return vim.fn.input("Binary: ", vim.fn.getcwd() .. "/target/debug/", "file")
      end,
      cwd = "${workspaceFolder}",
      stopOnEntry = false,
      runInTerminal = true,
      console = "integratedTerminal",
    },
  }

  -- Clean highlight group for the stopped line
  vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })
end

return M
