return {
  "hudson-trading/slang-server.nvim",
  ft = { "systemverilog", "verilog" },
  dependencies = { "MunifTanjim/nui.nvim" },
  opts = {
    root_dir = vim.fn.getcwd(),
  },
  config = function(_, opts)
    -- IMPORTANT:
    -- - svlangserver (IMC) and slang-server (Hudson/Slang) are different servers.
    -- - Do NOT run both on the same buffer.
    -- This plugin is only a last-resort fallback if neither svlangserver nor Verible LSP exists.
    if vim.fn.executable("svlangserver") == 1 then
      return
    end
    if vim.fn.executable("verible-verilog-ls") == 1 then
      return
    end
    if vim.fn.executable("slang-server") ~= 1 then
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
