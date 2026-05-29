return {
  {
    -- Neovim 0.12.x requires the rewritten nvim-treesitter on the main branch.
    "nvim-treesitter/nvim-treesitter",
    dependencies = { 'neovim-treesitter/treesitter-parser-registry' },
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      local have = {}
      for _, v in ipairs(opts.ensure_installed) do
        have[v] = true
      end

      -- On the new nvim-treesitter registry, SystemVerilog is provided as
      -- "systemverilog" (query repo + parser target), not "verilog".
      for _, lang in ipairs({ "systemverilog", "markdown", "markdown_inline", "html", "yaml" }) do
        if not have[lang] then
          table.insert(opts.ensure_installed, lang)
        end
      end

      opts.auto_install = true

      -- Reuse the systemverilog parser for both :set ft=systemverilog and :set ft=verilog.
      -- This avoids warnings like: [nvim-treesitter] skipping unsupported language: verilog
      vim.treesitter.language.register("systemverilog", { "systemverilog", "verilog" })

      return opts
    end,
  },
}
