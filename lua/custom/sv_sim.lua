local M = {}

-- ============================================================================
-- SystemVerilog Simulation Commands
-- ============================================================================

local function has(bin)
  return vim.fn.executable(bin) == 1
end

local function get_project_root()
  local bufnr = vim.api.nvim_get_current_buf()
  local fname = vim.api.nvim_buf_get_name(bufnr)
  local root = vim.fs.root(fname, { ".git", "verible.filelist", "Makefile", "sim" })
  return root or vim.fs.dirname(fname)
end

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "SV Sim" })
end

local function run_job(cmd, opts)
  opts = opts or {}
  local root = opts.cwd or get_project_root()
  notify("Running: " .. table.concat(cmd, " "))
  vim.fn.jobstart(cmd, {
    cwd = root,
    on_exit = function(_, code)
      if code == 0 then
        notify("Success", vim.log.levels.INFO)
      else
        notify("Failed (exit code: " .. code .. ")", vim.log.levels.ERROR)
      end
      if opts.on_exit then opts.on_exit(code) end
    end,
    on_stdout = function(_, data)
      if data and opts.on_stdout then opts.on_stdout(data) end
    end,
    on_stderr = function(_, data)
      if data and opts.on_stderr then opts.on_stderr(data) end
    end,
  })
end

-- ============================================================================
-- iverilog commands
-- ============================================================================

function M.iverilog_compile()
  local root = get_project_root()
  local cmd = { "iverilog", "-g2012", "-Wall", "-Winfloop" }
  
  -- Include directories
  local includes = vim.fn.globpath(root, "**/include", false, true)
  for _, inc in ipairs(includes) do
    table.insert(cmd, "-I" .. inc)
  end
  
  -- Source files
  local sources = vim.fn.globpath(root, "**/*.{v,sv,svh}", false, true)
  if #sources == 0 then
    notify("No Verilog/SystemVerilog source files found", vim.log.levels.WARN)
    return
  end
  vim.list_extend(cmd, sources)
  
  -- Output
  table.insert(cmd, "-o")
  table.insert(cmd, root .. "/simv")
  
  run_job(cmd, {
    on_exit = function(code)
      if code == 0 then
        notify("iverilog: Compiled to " .. root .. "/simv", vim.log.levels.INFO)
      end
    end,
  })
end

function M.iverilog_run()
  local root = get_project_root()
  local simv = root .. "/simv"
  if vim.fn.filereadable(simv) == 0 then
    notify("simv not found. Run :SVIverilogCompile first.", vim.log.levels.WARN)
    return
  end
  run_job({ simv }, {
    on_stdout = function(data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then print(line) end
        end
      end
    end,
  })
end

function M.iverilog_compile_run()
  M.iverilog_compile()
  -- Wait a bit then run
  vim.defer_fn(function()
    M.iverilog_run()
  end, 1000)
end

-- ============================================================================
-- Verilator commands
-- ============================================================================

function M.verilator_build()
  local root = get_project_root()
  if not has("verilator") then
    notify("verilator not in PATH", vim.log.levels.ERROR)
    return
  end
  
  -- Find top module
  local top = vim.fn.input("Top module name: ", "top")
  if top == "" then return end
  
  local cmd = { "verilator", "--cc", "--exe", "--build", "-j0", "--timing", "-Wall" }
  
  -- Include directories
  local includes = vim.fn.globpath(root, "**/include", false, true)
  for _, inc in ipairs(includes) do
    table.insert(cmd, "-I" .. inc)
  end
  
  -- Source files
  local sources = vim.fn.globpath(root, "**/*.{v,sv,svh}", false, true)
  if #sources == 0 then
    notify("No source files found", vim.log.levels.WARN)
    return
  end
  vim.list_extend(cmd, sources)
  
  -- Top module
  table.insert(cmd, "--top-module")
  table.insert(cmd, top)
  
  -- C++ main file (create simple one if needed)
  local main_cpp = root .. "/sim_main.cpp"
  if vim.fn.filereadable(main_cpp) == 0 then
    local f = io.open(main_cpp, "w")
    if f then
      f:write([[
#include "V]] .. top .. [[.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);
  V]] .. top .. [[* top = new V]] .. top .. [[();
  Verilated::traceEverOn(true);
  VerilatedVcdC* tfp = new VerilatedVcdC;
  top->trace(tfp, 99);
  tfp->open("]] .. top .. [[.vcd");
  
  while (!Verilated::gotFinish()) {
    top->eval();
    tfp->dump(Verilated::time());
    Verilated::timeInc(1);
  }
  
  top->final();
  tfp->close();
  delete top;
  delete tfp;
  return 0;
}
]])
      f:close()
    end
  end
  table.insert(cmd, main_cpp)
  
  run_job(cmd, { cwd = root })
end

function M.verilator_lint()
  local root = get_project_root()
  if not has("verilator") then
    notify("verilator not in PATH", vim.log.levels.ERROR)
    return
  end
  
  local cmd = { "verilator", "--lint-only", "-Wall", "-Wno-UNUSED", "-Wno-UNDRIVEN" }
  
  local sources = vim.fn.globpath(root, "**/*.{v,sv,svh}", false, true)
  if #sources == 0 then
    notify("No source files found", vim.log.levels.WARN)
    return
  end
  vim.list_extend(cmd, sources)
  
  run_job(cmd, { cwd = root })
end

function M.verilator_run()
  local root = get_project_root()
  local top = vim.fn.input("Top module name: ", "top")
  if top == "" then return end
  
  local obj_dir = root .. "/obj_dir"
  local simv = obj_dir .. "/V" .. top
  if vim.fn.filereadable(simv) == 0 then
    notify("Verilator build not found. Run :SVVerilatorBuild first.", vim.log.levels.WARN)
    return
  end
  
  run_job({ simv }, {
    cwd = obj_dir,
    on_stdout = function(data)
      if data then
        for _, line in ipairs(data) do
          if line ~= "" then print(line) end
        end
      end
    end,
  })
end

-- ============================================================================
-- Waveform viewer
-- ============================================================================

function M.open_waveform()
  local root = get_project_root()
  local vcd_files = vim.fn.globpath(root, "*.vcd", false, true)
  if #vcd_files == 0 then
    vcd_files = vim.fn.globpath(root, "obj_dir/*.vcd", false, true)
  end
  if #vcd_files == 0 then
    notify("No .vcd files found", vim.log.levels.WARN)
    return
  end
  
  local vcd = vcd_files[1]
  if #vcd_files > 1 then
    vcd = vim.fn.inputlist(vim.list_extend({ "Select VCD file:" }, vcd_files))
    if vcd < 1 or vcd > #vcd_files then return end
    vcd = vcd_files[vcd]
  end
  
  if has("gtkwave") then
    vim.fn.jobstart({ "gtkwave", vcd }, { detach = true })
    notify("Opened " .. vcd .. " in GTKWave", vim.log.levels.INFO)
  elseif has("surfer") then
    vim.fn.jobstart({ "surfer", vcd }, { detach = true })
    notify("Opened " .. vcd .. " in Surfer", vim.log.levels.INFO)
  else
    notify("No waveform viewer found (gtkwave/surfer)", vim.log.levels.WARN)
  end
end

-- ============================================================================
-- Create user commands
-- ============================================================================

vim.api.nvim_create_user_command("SVIverilogCompile", M.iverilog_compile, { desc = "Compile SystemVerilog with iverilog" })
vim.api.nvim_create_user_command("SVIverilogRun", M.iverilog_run, { desc = "Run iverilog simulation" })
vim.api.nvim_create_user_command("SVIverilogCompileRun", M.iverilog_compile_run, { desc = "Compile and run with iverilog" })

vim.api.nvim_create_user_command("SVVerilatorBuild", M.verilator_build, { desc = "Build SystemVerilog with Verilator" })
vim.api.nvim_create_user_command("SVVerilatorLint", M.verilator_lint, { desc = "Lint SystemVerilog with Verilator" })
vim.api.nvim_create_user_command("SVVerilatorRun", M.verilator_run, { desc = "Run Verilator simulation" })

vim.api.nvim_create_user_command("SVWaveform", M.open_waveform, { desc = "Open waveform viewer (GTKWave/Surfer)" })

return M