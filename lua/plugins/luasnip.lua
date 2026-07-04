return {
  -- LuaSnip configuration
  {
    "L3MON4D3/LuaSnip",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load()
      
      -- Key mappings for snippet expansion
      local ls = require("luasnip")
      vim.keymap.set({ "i", "s" }, "<Tab>", function()
        if ls.expand_or_jumpable() then
          ls.expand_or_jump()
        else
          return "<Tab>"
        end
      end, { expr = true, silent = true, desc = "LuaSnip: expand or jump" })
      
      vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
        if ls.jumpable(-1) then
          ls.jump(-1)
        end
      end, { silent = true, desc = "LuaSnip: jump back" })
      
      vim.keymap.set({ "i", "s" }, "<C-j>", function()
        if ls.choice_active() then
          ls.change_choice(1)
        end
      end, { silent = true, desc = "LuaSnip: next choice" })
      
      vim.keymap.set({ "i", "s" }, "<C-k>", function()
        if ls.choice_active() then
          ls.change_choice(-1)
        end
      end, { silent = true, desc = "LuaSnip: prev choice" })
      
      -- Load custom SystemVerilog snippets AFTER LuaSnip is fully set up
      local ok, _ = pcall(require, "custom.sv_snippets")
      if not ok then
        vim.notify("Failed to load custom.sv_snippets", vim.log.levels.WARN)
      end
    end,
  },
}