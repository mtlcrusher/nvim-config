-- plugins/dap.lua
-- nvim-dap core + the ecosystem most users want by default:
--   * nvim-dap           debug-adapter protocol client
--   * nvim-nio           async lib dependency of nvim-dap-ui
--   * nvim-dap-ui        the UI overlay (scopes/variables/watches/repl/stacks)
--   * nvim-dap-virtual-text inline variable-value virtual text at stopped lines
--
-- Adapter installation (debugpy, codelldb, gdb) is handled by mason-nvim-dap
-- in plugins/mason.lua — this keeps that concern in one place.
return {
  {
    "mfussenegger/nvim-dap",
    lazy = true,
    keys = {
      { "<leader>dc", function() require("dap").continue() end,    desc = "DAP: Continue" },
      { "<leader>dn", function() require("dap").step_over() end,   desc = "DAP: Step over" },
      { "<leader>di", function() require("dap").step_into() end,   desc = "DAP: Step into" },
      { "<leader>do", function() require("dap").step_out() end,    desc = "DAP: Step out" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "DAP: Toggle breakpoint" },
      { "<leader>dB", function() require("dap").clear_breakpoints() end, desc = "DAP: Clear breakpoints" },
      {
        "<leader>dC",
        function()
          require("dap").set_breakpoint(vim.fn.input "Condition: ")
        end,
        desc = "DAP: Conditional breakpoint",
      },
      {
        "<leader>dL",
        function()
          require("dap").set_breakpoint(nil, nil, vim.fn.input "Log message: ")
        end,
        desc = "DAP: Logpoint",
      },
      { "<leader>dr", function() require("dap").repl.open() end,  desc = "DAP: REPL open" },
      { "<leader>dl", function() require("dap").run_last() end,   desc = "DAP: Run last" },
      { "<leader>dx", function() require("dap").terminate() end,  desc = "DAP: Terminate" },
    },
    dependencies = {
      { "rcarriga/nvim-dap-ui",           dependencies = { "nvim-neotest/nvim-nio" } },
      { "theHamsta/nvim-dap-virtual-text" },
    },
    config = function()
      require "configs.dap"
    end,
  },
}
