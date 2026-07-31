-- configs/dap.lua
-- Central nvim-dap configuration: adapters + per-language launch configs.
-- Languages: Python (debugpy), C/C++ (codelldb, gdb), Rust (rustaceanvim → codelldb).
-- Adapter discovery via `has()` (system binaries), matching configs/lspconfig.lua style.
-- No Mason. No hardcoded paths beyond `has()` fallbacks.

local M = {}

local function has(bin)
  return vim.fn.executable(bin) == 1
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

  local vtext = pcall(require, "nvim-dap-virtual-text")
  if vtext then
    require("nvim-dap-virtual-text").setup {
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
  vim.fn.sign_define("DapBreakpoint",       { text = "", texthl = "DiagnosticSignError", linehl = "", numhl = "" })
  vim.fn.sign_define("DapBreakpointCondition", { text = "", texthl = "DiagnosticSignWarn",  linehl = "", numhl = "" })
  vim.fn.sign_define("DapBreakpointRejected",  { text = "", texthl = "DiagnosticSignHint",  linehl = "", numhl = "" })
  vim.fn.sign_define("DapStopped",          { text = "", texthl = "DiagnosticSignInfo",    linehl = "DapStoppedLine", numhl = "DapStoppedLine" })

  -- Auto-open/close dap-ui on session start/end
  dap.listeners.after.event_initialized.dapui = function() dapui.open { reset = true } end
  dap.listeners.before.event_terminated.dapui = function() dapui.close() end
  dap.listeners.before.event_exited.dapui = function() dapui.close() end

  -- ──────────────────────────────────────────────────────────────────
  -- Adapters (system binaries only; no Mason)
  -- ──────────────────────────────────────────────────────────────────

  -- codelldb (preferred C/C++/Rust adapter) — installed to ~/.local/bin or PATH
  -- SKIPPED on Termux: codelldb is a glibc binary and crashes on bionic libc
  if has "codelldb" and vim.fn.executable("termux-info") ~= 1 then
    dap.adapters.codelldb = {
      type = "server",
      port = "${port}",
      executable = {
        command = vim.fn.exepath "codelldb",
        args = { "--port", "${port}" },
        detached = false,
      },
    }
  end

  -- gdb (fallback C/C++ adapter; user installs via apt/brew)
  -- On Termux/Android, GDB's DAP adapter crashes due to Python version mismatch
  -- (GDB 16.3 built against Python 3.13, Termux has Python 3.14).
  -- Use gdbserver + attach mode instead (see project .nvim-dap.lua configs).
  if has "gdb" and not (vim.loop.os_uname().sysname == "Linux" and vim.fn.executable("termux-info") == 1) then
    dap.adapters.gdb = {
      type = "executable",
      command = "gdb",
      args = { "--interpreter=dap" },
    }
  end

  -- Python (debugpy) — installed via pip: `python3 -m pip install --user debugpy`
  if has "python3" then
    dap.adapters.python = {
      type = "executable",
      command = vim.fn.exepath "python3",
      args = { "-m", "debugpy.adapter" },
      options = { source_file_type = "python" },
    }
  end

  -- ──────────────────────────────────────────────────────────────────
  -- Per-language configurations
  -- ──────────────────────────────────────────────────────────────────

  -- Python ────────────────────────────────────────────────────────────
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
      module = function() return vim.fn.input "Module: " end,
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
      pathMappings = { { localRoot = "${workspaceFolder}", remoteRoot = "." } },
    },
  }

  -- C / C++ ───────────────────────────────────────────────────────────
  -- Three adapter choices if present: codelldb (preferred), gdb (fallback)
  -- codelldb SKIPPED on Termux (glibc binary on bionic libc)
  local c_cfgs = {}

  if has "codelldb" and vim.fn.executable("termux-info") ~= 1 then
    -- Launch native binary under codelldb
    table.insert(c_cfgs, {
      type = "codelldb",
      request = "launch",
      name = "C/C++: Launch (codelldb)",
      program = function() return vim.fn.input("Binary: ", vim.fn.expand "%:p:h" .. "/", "file") end,
      cwd = "${workspaceFolder}",
      stopOnEntry = false,
      args = function()
        local a = vim.fn.input "Args (space-separated): "
        return a == "" and {} or vim.split(a, " ", { trimempty = true })
      end,
      runInTerminal = true,
      console = "integratedTerminal",
    })
    -- Remote attach to gdbserver (OpenOCD/J-Link/QEMU) for embedded RISC-V/ARM
    table.insert(c_cfgs, {
      type = "codelldb",
      request = "attach",
      name = "C/C++: Attach remote (gdbserver 127.0.0.1:3333)",
      program = function() return vim.fn.input("Binary (with symbols): ", vim.fn.expand "%:p:h" .. "/", "file") end,
      cwd = "${workspaceFolder}",
      initCommands = function()
        local init = vim.fn.findfile(".gdbinit", vim.fn.getcwd() .. ";")
        return init ~= "" and { "command source " .. init } or {}
      end,
      sourceLanguages = { "c", "cpp", "rust" },
      gdbRemote = {
        host = function() return vim.fn.input("Host: ", "127.0.0.1") end,
        port = function()
          local p = vim.fn.input("Port: ", "3333")
          return tonumber(p) or 3333
        end,
      },
    })
  end

  if has "gdb" then
      table.insert(c_cfgs, {
        type = "gdb",
        request = "launch",
        name = "C/C++: Launch (gdb)",
        program = function() return vim.fn.input("Binary: ", vim.fn.expand "%:p:h" .. "/", "file") end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        args = function()
          local a = vim.fn.input "Args (space-separated): "
          return a == "" and {} or vim.split(a, " ", { trimempty = true })
        end,
      })
      -- gdbserver attach (works on Termux where gdb DAP crashes on launch)
      table.insert(c_cfgs, {
        type = "gdb",
        request = "attach",
        name = "C/C++: Attach to gdbserver (localhost:1234)",
        program = function() return vim.fn.input("Binary (with symbols): ", vim.fn.expand "%:p:h" .. "/", "file") end,
        cwd = "${workspaceFolder}",
        connect = {
          host = "127.0.0.1",
          port = 1234,
        },
      })
    end

  dap.configurations.c = c_cfgs
  dap.configurations.cpp = c_cfgs

  -- Rust ──────────────────────────────────────────────────────────────
  -- rustaceanvim owns the Rust DAP adapter and configs entirely.
  -- No fallback here — rustaceanvim injects its own configs when it loads.
  -- If rustaceanvim is not loaded, the user can add configs manually or
  -- install rustaceanvim.

  -- Highlight for stopped line
  vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

  -- ──────────────────────────────────────────────────────────────────
  -- Load project-local DAP config (.nvim-dap.lua) if present
  -- ──────────────────────────────────────────────────────────────────
  local function load_project_dap()
    local cwd = vim.fn.getcwd()
    local config_path = cwd .. "/.nvim-dap.lua"
    if vim.fn.filereadable(config_path) == 1 then
      local ok, project_dap = pcall(dofile, config_path)
      if ok then
        -- Load project adapters first (so configs can reference them)
        if project_dap.adapters then
          for adapter_name, adapter_config in pairs(project_dap.adapters) do
            dap.adapters[adapter_name] = adapter_config
          end
          vim.notify("Loaded project DAP adapters: " .. vim.inspect(vim.tbl_keys(project_dap.adapters)), vim.log.levels.INFO)
        end
        
        -- Replace configurations for each language
        if project_dap.configurations then
          for lang, cfgs in pairs(project_dap.configurations) do
            dap.configurations[lang] = cfgs
          end
          vim.notify("Loaded project DAP config: " .. config_path, vim.log.levels.INFO)
          if project_dap.gdbserver_cmd then
            vim.g.project_gdbserver_cmd = project_dap.gdbserver_cmd
          end
        end
      end
    end
  end
  
  -- Auto-load on VimEnter (after global config is set)
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      vim.defer_fn(load_project_dap, 100)
    end,
    once = true,
  })
  
  -- Reload on directory change
  vim.api.nvim_create_autocmd("DirChanged", {
    pattern = "*",
    callback = function()
      vim.defer_fn(load_project_dap, 100)
    end,
  })
  
  -- Manual reload command
  vim.api.nvim_create_user_command("DapLoadProject", load_project_dap, { desc = "Load project .nvim-dap.lua" })
  
  -- Show gdbserver command
  vim.api.nvim_create_user_command("DapGdbserverCmd", function()
    if vim.g.project_gdbserver_cmd then
      print(vim.g.project_gdbserver_cmd)
    else
      print("No project gdbserver command")
    end
  end, { desc = "Show project gdbserver command" })
end

return M