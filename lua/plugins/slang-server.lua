return {
  "hudson-trading/slang-server.nvim",
  lazy = false,
  dependencies = {
    "MunifTanjim/nui.nvim",
  },
  opts = {},
  config = function()
    vim.lsp.config("slang-server", {
      cmd = { "slang-server" },
      filetypes = { "systemverilog", "verilog" },
      root_markers = { ".git", ".slang" },
      single_file_support = true,
      -- optional: jika kamu ingin mengatur capabilities atau on_attach
      -- capabilities = vim.lsp.protocol.make_client_capabilities(),
      -- on_attach = function(client, bufnr) ... end,
    })
    vim.lsp.enable("slang-server")
  end,
}

