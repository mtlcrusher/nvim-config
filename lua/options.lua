require "nvchad.options"


-- filetypes for Verilog/SystemVerilog
vim.filetype.add({
  extension = {
    sv = "systemverilog",
    svh = "systemverilog",
    v = "verilog",
    vh = "verilog",
  },
})

-- add yours here!

-- local o = vim.o
-- o.cursorlineopt ='both' -- to enable cursorline!

require("custom.utils.clipboard").setup()
