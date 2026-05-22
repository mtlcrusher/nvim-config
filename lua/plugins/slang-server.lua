return {
  "hudson-trading/slang-server.nvim",
  ft = { "systemverilog", "verilog" },
  dependencies = { "MunifTanjim/nui.nvim" },
  opts = {
    root_dir = vim.fn.getcwd(),
  },
  config = function(_, opts)
    -- If Verible language server is available, prefer it to avoid running two LSPs.
    if vim.fn.executable("verible-verilog-ls") == 1 then
      return
    end

    require("slang-server").setup(opts)
    vim.lsp.config("slang-server", {
      cmd = { "slang-server" },
      filetypes = { "systemverilog", "verilog" },
      root_markers = { ".git", ".slang" },
    })
    vim.lsp.enable("slang-server")
  end,
}
