local M = {}

-- ============================================================================
-- SystemVerilog Code Generation Templates
-- ============================================================================

M.templates = {
  -- Module template
  module = [[
module ${1:module_name} #(
  parameter int ${2:PARAM_NAME} = ${3:DEFAULT_VALUE}
) (
  input  logic        clk,
  input  logic        rst_n,
  ${4:/* ports */}
);

  ${5:/* local parameters */}
  ${6:/* signals */}
  ${7:/* sequential logic */}
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ${8:/* reset values */}
    end else begin
      ${9:/* next state logic */}
    end
  end

  ${10:/* combinational logic */}
  always_comb begin
    ${11:/* comb logic */}
  end

  ${12:/* assertions */}
  ${13:/* coverage */}

endmodule : ${1:module_name}
]],

  -- Interface template
  interface = [[
interface ${1:interface_name} #(
  parameter int ${2:PARAM_NAME} = ${3:DEFAULT_VALUE}
);

  logic        clk;
  logic        rst_n;
  ${4:/* signals */}

  ${5:/* clocking blocks */}
  clocking cb @(posedge clk);
    ${6:/* input/output signals */}
  endclocking

  ${7:/* modports */}
  modport ${8:mp_name} (
    input  ${9:/* input signals */},
    output ${10:/* output signals */}
  );

  ${11:/* assertions */}

endinterface : ${1:interface_name}
]],

  -- Package template
  package = [[
package ${1:package_name};

  ${2:/* typedefs */}
  typedef enum logic [${3:1}:0] {
    ${4:ENUM_VAL1} = ${5:2'd0},
    ${6:ENUM_VAL2} = ${7:2'd1}
  } ${8:enum_name_e};

  typedef struct packed {
    ${9:logic [7:0] field1;},
    ${10:logic [15:0] field2;}
  } ${11:struct_name_t};

  ${12:/* parameters */}
  parameter int ${13:PACKAGE_PARAM} = ${14:32};

  ${15:/* functions */}
  function automatic logic [${16:31}:0] ${17:function_name} (input logic [${18:7}:0] arg);
    ${19:/* body */}
    return ${20:32'd0};
  endfunction

  ${21:/* tasks */}
  task automatic ${22:task_name} (input logic [${23:7}:0] arg);
    ${24:/* body */}
  endtask

endpackage : ${1:package_name}
]],

  -- Testbench template
  testbench = [[
module ${1:dut_name}_tb;

  ${2:/* parameters */}
  parameter int ${3:CLOCK_PERIOD} = 10;

  ${4:/* signals */}
  logic        clk;
  logic        rst_n;
  ${5:/* DUT ports */}

  ${6:/* clock generation */}
  initial clk = 0;
  always #(${3:CLOCK_PERIOD}/2) clk = ~clk;

  ${7:/* reset generation */}
  initial begin
    rst_n = 0;
    repeat (2) @(posedge clk);
    rst_n = 1;
  end

  ${8:/* DUT instantiation */}
  ${1:dut_name} dut_inst (
    .clk   (clk),
    .rst_n (rst_n),
    ${9:/* port connections */}
  );

  ${10:/* stimulus */}
  initial begin
    ${11:/* test sequence */}
    $finish;
  end

  ${12:/* assertions */}
  ${13:/* coverage */}

endmodule : ${1:dut_name}_tb
]],

  -- Sequence template
  sequence = [[
sequence ${1:sequence_name};
  ${2:/* sequence expression */}
  ${3:signal_name} ##[${4:1}:${5:5}] ${6:other_signal};
endsequence : ${1:sequence_name}
]],

  -- Property template
  property = [[
property ${1:property_name};
  ${2:/* property expression */}
  @(posedge clk) disable iff (!rst_n)
    ${3:antecedent} |-> ${4:consequent};
endproperty : ${1:property_name}

${5:/* assertion */}
assert property (${1:property_name}) else $error("${6:Assertion failed: }", ${1:property_name});
]],

  -- Covergroup template
  covergroup = [[
covergroup ${1:covergroup_name} @(posedge clk);
  ${2:/* coverpoints */}
  ${3:coverpoint_name} : coverpoint ${4:signal_name} {
    bins ${5:bin_name} = {${6:values}};
  }
  ${7:/* cross coverage */}
  ${8:cross_name} : cross ${9:cp1}, ${10:cp2};
endgroup : ${1:covergroup_name}

${11:/* instantiation */}
${1:covergroup_name} ${12:cg_inst} = new();
]],

  -- FSM template
  fsm = [[
typedef enum logic [${1:1}:0] {
  ${2:S_IDLE}  = ${3:2'd0},
  ${4:S_STATE1} = ${5:2'd1},
  ${6:S_STATE2} = ${7:2'd2}
} ${8:state_e};

${8:state_e} current_state, next_state;

always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    current_state <= ${2:S_IDLE};
  end else begin
    current_state <= next_state;
  end
end

always_comb begin
  next_state = current_state;
  unique case (current_state)
    ${2:S_IDLE}:   if (${9:condition}) next_state = ${4:S_STATE1};
    ${4:S_STATE1}: if (${10:condition}) next_state = ${6:S_STATE2};
    ${6:S_STATE2}: if (${11:condition}) next_state = ${2:S_IDLE};
    default:       next_state = ${2:S_IDLE};
  endcase
end

// Output logic
always_comb begin
  unique case (current_state)
    ${2:S_IDLE}:   ${12:output} = ${13:value};
    ${4:S_STATE1}: ${12:output} = ${14:value};
    ${6:S_STATE2}: ${12:output} = ${15:value};
    default:       ${12:output} = ${16:value};
  endcase
end
]],

  -- Assertions cheat sheet
  assertions = [[
// Immediate assertions
assert (condition) else $error("Message");
assume (condition);
cover (condition);

// Concurrent assertions
assert property (@(posedge clk) disable iff (!rst_n) a |-> b);
assert property (@(posedge clk) disable iff (!rst_n) a |=> b);  // next cycle
assert property (@(posedge clk) disable iff (!rst_n) a |-> ##[1:5] b);  // 1-5 cycles
assert property (@(posedge clk) disable iff (!rst_n) a |-> b [*3]);  // 3 consecutive
assert property (@(posedge clk) disable iff (!rst_n) a |-> b [->3]);  // 3rd occurrence
assert property (@(posedge clk) disable iff (!rst_n) a |-> b [=3]);   // 3rd occurrence non-consecutive

// Sequence operators
// ##1  - next cycle
// ##[1:5] - 1 to 5 cycles
// *    - zero or more
// [*3] - exactly 3
// [->3] - 3rd occurrence
// [=3] - 3rd occurrence non-consecutive
// or   - union
// and  - intersection
// intersect - both must match
]],

  -- UVM component skeleton
  uvm_component = [[
class ${1:component_name} extends uvm_${2:component_type};

  \`uvm_component_utils(${1:component_name})

  // Analysis ports
  uvm_analysis_port #(${3:transaction_type}) ${4:ap_name};

  // Constructor
  function new(string name = "${1:component_name}", uvm_component parent = null);
    super.new(name, parent);
    ${4:ap_name} = new("${4:ap_name}", this);
  endfunction

  // Build phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ${5:/* get config, create sub-components */}
  endfunction

  // Connect phase
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    ${6:/* connect ports */}
  endfunction

  // Run phase
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    ${7:/* main logic */}
  endtask

  // Extract phase
  function void extract_phase(uvm_phase phase);
    super.extract_phase(phase);
    ${8:/* extract coverage */}
  endfunction

endclass : ${1:component_name}
]],

  -- UVM sequence
  uvm_sequence = [[
class ${1:sequence_name} extends uvm_sequence #(${2:transaction_type});

  \`uvm_object_utils(${1:sequence_name})

  function new(string name = "${1:sequence_name}");
    super.new(name);
  endfunction

  task body();
    ${3:/* sequence logic */}
    \`uvm_do_with(req, { ${4:/* constraints */} })
  endtask

endclass : ${1:sequence_name}
]],
}

-- ============================================================================
-- Template expansion helper
-- ============================================================================

function M.expand_template(template_name, substitutions)
  local template = M.templates[template_name]
  if not template then
    vim.notify("Template not found: " .. template_name, vim.log.levels.ERROR)
    return nil
  end

  -- Simple placeholder replacement: ${N:default} -> default or substituted value
  local result = template:gsub("%${(%d+):([^}]+)}", function(num, default)
    local key = tonumber(num)
    return substitutions[key] or default
  end)

  -- Replace remaining ${N} without defaults
  result = result:gsub("%${(%d+)}", function(num)
    local key = tonumber(num)
    return substitutions[key] or ""
  end)

  return result
end

function M.insert_template(template_name, substitutions)
  local expanded = M.expand_template(template_name, substitutions or {})
  if not expanded then return end

  local lines = vim.split(expanded, "\n")
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row, row, false, lines)
end

-- ============================================================================
-- Quick template commands
-- ============================================================================

function M.create_module()
  local name = vim.fn.input("Module name: ", "my_module")
  if name == "" then return end
  M.insert_template("module", { name })
end

function M.create_interface()
  local name = vim.fn.input("Interface name: ", "my_if")
  if name == "" then return end
  M.insert_template("interface", { name })
end

function M.create_package()
  local name = vim.fn.input("Package name: ", "my_pkg")
  if name == "" then return end
  M.insert_template("package", { name })
end

function M.create_testbench()
  local dut = vim.fn.input("DUT module name: ", "my_dut")
  if dut == "" then return end
  M.insert_template("testbench", { dut })
end

function M.create_fsm()
  M.insert_template("fsm", {})
end

function M.create_covergroup()
  local name = vim.fn.input("Covergroup name: ", "my_cg")
  if name == "" then return end
  M.insert_template("covergroup", { name })
end

return M