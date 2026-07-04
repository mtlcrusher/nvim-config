-- SystemVerilog snippets for LuaSnip
-- Loaded via LuaSnip's snippet loader (lazy-loaded)

local function load_sv_snippets()
  local ok, ls = pcall(require, "luasnip")
  if not ok then
    vim.notify("LuaSnip not available for SV snippets", vim.log.levels.DEBUG)
    return
  end

  local s = ls.snippet
  local t = ls.text_node
  local i = ls.insert_node
  local f = ls.function_node
  local c = ls.choice_node
  local d = ls.dynamic_node
  local sn = ls.snippet_node
  local fmt = require("luasnip.extras.fmt").fmt
  local rep = require("luasnip.extras").rep

  -- Helper: get filename without extension for default module name
  local function filename()
    return vim.fn.expand("%:t:r")
  end

  ls.add_snippets("systemverilog", {
    -- Module template
    s(
      { trig = "module", desc = "SystemVerilog module template" },
      fmt(
        [[
module {} #(
  parameter int {} = {}
) (
  input  logic        {},
  output logic        {}
);

  // Internal signals
  {}

  // Logic
  {}

endmodule : {}
      ]],
      {
        f(filename, {}),
        i(1, "PARAM_NAME"),
        i(2, "DEFAULT_VALUE"),
        i(3, "clk"),
        i(4, "rst_n"),
        i(5, "// signals"),
        i(6, "// logic"),
        f(filename, {}),
      }
    )
  ),

  -- Parameterized module
  s(
    { trig = "pmod", desc = "Parameterized module template" },
    fmt(
      [[
module {} #(
  parameter int {} = {},
  parameter int {} = {}
) (
  input  logic        {},
  input  logic        {},
  output logic        {}
);

  // Internal signals
  {}

  // Logic
  {}

endmodule : {}
      ]],
      {
        f(filename, {}),
        i(1, "WIDTH"),
        i(2, "8"),
        i(3, "DEPTH"),
        i(4, "16"),
        i(5, "clk"),
        i(6, "rst_n"),
        i(7, "out"),
        i(8, "// signals"),
        i(9, "// logic"),
        f(filename, {}),
      }
    )
  ),

  -- Interface template
  s(
    { trig = "interface", desc = "SystemVerilog interface template" },
    fmt(
      [[
interface {} #(
  parameter int {} = {}
) (
  input logic {}
);

  // Signals
  logic {};

  // Modports
  modport {} (
    input  {},
    output {}
  );
  modport {} (
    input  {},
    output {}
  );

  // Clocking blocks
  clocking @(posedge {});
  endclocking

endinterface : {}
      ]],
      {
        f(filename, {}),
        i(1, "DATA_WIDTH"),
        i(2, "32"),
        i(3, "clk"),
        i(4, "signal_name"),
        i(5, "master"),
        i(6, "input_sigs"),
        i(7, "output_sigs"),
        i(8, "slave"),
        i(9, "input_sigs"),
        i(10, "output_sigs"),
        i(11, "clk"),
        f(filename, {}),
      }
    )
  ),

  -- Package template
  s(
    { trig = "package", desc = "SystemVerilog package template" },
    fmt(
      [[
package {};

  // Types
  typedef enum logic [1:0] {{
    {} = 2'b00,
    {} = 2'b01,
    {} = 2'b10
  }} {}_e;

  typedef struct packed {{
    logic [31:0] {};
    logic [15:0] {};
    logic [7:0]  {};
  }} {}_t;

  // Constants
  localparam int {} = {};

  // Functions
  function automatic logic {} (input logic [31:0] {});
    return 1'b0;
  endfunction

  // Tasks
  task automatic {} (input logic [31:0] {});
  endtask

endpackage : {}
      ]],
      {
        f(filename, {}),
        i(1, "STATE_IDLE"),
        i(2, "STATE_ACTIVE"),
        i(3, "STATE_DONE"),
        i(4, "state"),
        i(5, "field1"),
        i(6, "field2"),
        i(7, "field3"),
        i(8, "struct_name"),
        i(9, "CONST_NAME"),
        i(10, "VALUE"),
        i(11, "func_name"),
        i(12, "arg"),
        i(13, "task_name"),
        i(14, "arg"),
        f(filename, {}),
      }
    )
  ),

  -- Class template
  s(
    { trig = "class", desc = "SystemVerilog class template" },
    fmt(
      [[
class {} #(
  parameter int {} = {}
);

  // Properties
  rand logic [31:0] {};
  logic [15:0] {};

  // Constraints
  constraint {} {{
    {} < {};
  }}

  // Constructor
  function new(string name = "{}");
    super.new(name);
  endfunction

  // Methods
  virtual function void {}();
  endfunction

  virtual task {} ();
  endtask

endclass : {}
      ]],
      {
        f(filename, {}),
        i(1, "WIDTH"),
        i(2, "32"),
        i(3, "rand_field"),
        i(4, "normal_field"),
        i(5, "constraint_name"),
        i(6, "rand_field"),
        i(7, "MAX_VAL"),
        i(8, f(filename, {})),
        i(9, "method_name"),
        i(10, "task_name"),
        f(filename, {}),
      }
    )
  ),

  -- Testbench template
  s(
    { trig = "tb", desc = "SystemVerilog testbench template" },
    fmt(
      [[
module {}_tb;

  // Parameters
  parameter int {} = {};

  // Signals
  logic        {};
  logic        {};
  logic        {};

  // DUT instance
  {} dut (
    .{}   ({}),
    .{}  ({}),
    .{} ({})
  );

  // Clock generation
  initial {} = 0;
  always #{} {} = ~{};

  // Reset generation
  initial begin
    {} = 0;
    #{} {} = 1;
  end

  // Stimulus
  initial begin
    {}
    #{} $finish;
  end

  // Waveform dump
  initial begin
    $dumpfile("{}_tb.vcd");
    $dumpvars(0, {}_tb);
  end

endmodule : {}_tb
      ]],
      {
        f(filename, {}),
        i(1, "CLK_PERIOD"),
        i(2, "10"),
        i(3, "clk"),
        i(4, "rst_n"),
        i(5, "enable"),
        f(filename, {}),
        i(6, "clk"),
        i(7, "clk"),
        i(8, "rst_n"),
        i(9, "rst_n"),
        i(10, "out"),
        i(11, "out"),
        i(12, "clk"),
        i(13, "5"),
        i(14, "clk"),
        i(15, "clk"),
        i(16, "rst_n"),
        i(17, "20"),
        i(18, "rst_n"),
        i(19, "// stimulus here"),
        i(20, "1000"),
        f(filename, {}),
        f(filename, {}),
        f(filename, {}),
      }
    )
  ),

  -- Always_ff block
  s(
    { trig = "aff", desc = "always_ff block" },
    fmt(
      [[
always_ff @(posedge {} or negedge {}) begin
  if (!{}) begin
    {}
  end else begin
    {}
  end
end
      ]],
      {
        i(1, "clk"),
        i(2, "rst_n"),
        i(3, "rst_n"),
        i(4, "// reset logic"),
        i(5, "// sequential logic"),
      }
    )
  ),

  -- Always_comb block
  s(
    { trig = "acomb", desc = "always_comb block" },
    fmt(
      [[
always_comb begin
  {}
end
      ]],
      { i(1, "// combinational logic") }
    )
  ),

  -- Case statement
  s(
    { trig = "case", desc = "case statement" },
    fmt(
      [[
case ({})
  {}: begin
    {}
  end
  default: begin
    {}
  end
endcase
      ]],
      { i(1, "expr"), i(2, "value"), i(3, "// logic"), i(4, "// default logic") }
    )
  ),

  -- Casez statement
  s(
    { trig = "casez", desc = "casez statement" },
    fmt(
      [[
casez ({})
  {}: begin
    {}
  end
  default: begin
    {}
  end
endcase
      ]],
      { i(1, "expr"), i(2, "value"), i(3, "// logic"), i(4, "// default logic") }
    )
  ),

  -- Generate block
  s(
    { trig = "gen", desc = "generate block" },
    fmt(
      [[
generate
  for (genvar {} = 0; {} < {}; {}++) begin : {}
    {}
  end
endgenerate
      ]],
      {
        i(1, "i"),
        rep(1),
        i(2, "N"),
        rep(1),
        i(3, "gen_block"),
        i(4, "// generated logic"),
      }
    )
  ),

  -- Assertion
  s(
    { trig = "assert", desc = "SystemVerilog assertion" },
    fmt(
      [[
assert property (@(posedge {}) {} |-> {});
      ]],
      { i(1, "clk"), i(2, "condition"), i(3, "consequence") }
    )
  ),

  -- Cover property
  s(
    { trig = "cover", desc = "SystemVerilog cover property" },
    fmt(
      [[
cover property (@(posedge {}) {});
      ]],
      { i(1, "clk"), i(2, "property") }
    )
  ),

  -- Sequence
  s(
    { trig = "seq", desc = "SystemVerilog sequence" },
    fmt(
      [[
sequence {};
  @(posedge {}) {} ##{} {};
endsequence
      ]],
      { i(1, "seq_name"), i(2, "clk"), i(3, "start"), i(4, "delay"), i(5, "end") }
    )
  ),

  -- Property
  s(
    { trig = "prop", desc = "SystemVerilog property" },
    fmt(
      [[
property {};
  @(posedge {}) {} |=> {};
endproperty
      ]],
      { i(1, "prop_name"), i(2, "clk"), i(3, "antecedent"), i(4, "consequent") }
    )
  ),

  -- Clocking block
  s(
    { trig = "clocking", desc = "clocking block" },
    fmt(
      [[
clocking @(posedge {});
  default input #{} output #{}; 
  input  {};
  output {};
endclocking
      ]],
      { i(1, "clk"), i(2, "1step"), i(3, "1step"), i(4, "input_sigs"), i(5, "output_sigs") }
    )
  ),

  -- Modport
  s(
    { trig = "modport", desc = "modport declaration" },
    fmt(
      [[
modport {} (
  input  {},
  output {},
  inout  {}
);
      ]],
      { i(1, "modport_name"), i(2, "input_sigs"), i(3, "output_sigs"), i(4, "inout_sigs") }
    )
  ),

  -- Typedef enum
  s(
    { trig = "tenum", desc = "typedef enum" },
    fmt(
      [[
typedef enum logic [{}:0] {{
  {} = {},
  {} = {}
}} {}_e;
      ]],
      { i(1, "1"), i(2, "VAL1"), i(3, "0"), i(4, "VAL2"), i(5, "1"), i(6, "name") }
    )
  ),

  -- Typedef struct
  s(
    { trig = "tstruct", desc = "typedef struct packed" },
    fmt(
      [[
typedef struct packed {{
  logic [{}:0] {};
  logic [{}:0] {};
}} {}_t;
      ]],
      { i(1, "31"), i(2, "field1"), i(3, "15"), i(4, "field2"), i(5, "name") }
    )
  ),

  -- Function
  s(
    { trig = "func", desc = "function declaration" },
    fmt(
      [[
function automatic {} {} (input {} {});
  {}
  return {};
endfunction
      ]],
      { i(1, "logic"), i(2, "func_name"), i(3, "logic [31:0]"), i(4, "arg"), i(5, "// body"), i(6, "1'b0") }
    )
  ),

  -- Task
  s(
    { trig = "task", desc = "task declaration" },
    fmt(
      [[
task automatic {} (input {} {}, output {} {});
  {}
endtask
      ]],
      { i(1, "task_name"), i(2, "logic [31:0]"), i(3, "in_arg"), i(4, "logic [31:0]"), i(5, "out_arg"), i(6, "// body") }
    )
  ),

  -- Auto-inst trigger
  s(
    { trig = "ainst", desc = "Auto-inst module instance" },
    fmt(
      [[
{} {} (
  .{}  ({}),
  .{} ({})
);
      ]],
      { i(1, "module_name"), i(2, "inst_name"), i(3, "port1"), i(4, "sig1"), i(5, "port2"), i(6, "sig2") }
    )
  ),

  -- Interface instance
  s(
    { trig = "iinst", desc = "Interface instance" },
    fmt(
      [[
{} {} ();
      ]],
      { i(1, "interface_name"), i(2, "inst_name") }
    )
  ),
})

-- Also register for verilog filetype
ls.add_snippets("verilog", ls.get_snippets("systemverilog"))
end

-- Load immediately if LuaSnip is already available, otherwise defer
local ok, _ = pcall(require, "luasnip")
if ok then
  load_sv_snippets()
else
  vim.api.nvim_create_autocmd("User", {
    pattern = "LuaSnip*",
    callback = load_sv_snippets,
    once = true,
  })
end