return {
  {
    -- Pin to the legacy "master" branch for Neovim <=0.11 compatibility.
    -- The "main" branch is an incompatible rewrite.
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    lazy = false,
    build = ":TSUpdate",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      local have = {}
      for _, v in ipairs(opts.ensure_installed) do
        have[v] = true
      end
      if not have.verilog then
        table.insert(opts.ensure_installed, "verilog")
      end

      -- Install missing parsers automatically when entering buffers.
      opts.auto_install = true

      return opts
    end,
  },
}
