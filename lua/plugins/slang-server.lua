return {
  "hudson-trading/slang-server.nvim",
  ft = { "systemverilog", "verilog" },
  -- lazy = false,
  dependencies = { "MunifTanjim/nui.nvim" },
  opts = {
    root_dir = vim.fn.getcwd()
  },
  config = function(_, opts)
    require("slang-server").setup(opts)
    vim.lsp.config("slang-server", {
      cmd = { "slang-server" },
      filetypes = { "systemverilog", "verilog" },
      root_markers = { ".git", ".slang" }
    })
    vim.lsp.enable("slang-server")
  end,
}

