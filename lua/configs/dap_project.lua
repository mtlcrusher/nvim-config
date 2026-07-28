-- Project-local DAP configuration loader
-- Add to your global config (configs/dap.lua or plugins/dap.lua)

local M = {}

-- Load project-local .nvim-dap.lua if exists
function M.load_project_dap()
  local cwd = vim.fn.getcwd()
  local project_config_path = cwd .. "/.nvim-dap.lua"
  
  if vim.fn.filereadable(project_config_path) == 1 then
    local ok, project_dap = pcall(dofile, project_config_path)
    if ok then
      local dap = require("dap")
      
      -- Load project adapters first (so configs can reference them)
      if project_dap.adapters then
        for adapter_name, adapter_config in pairs(project_dap.adapters) do
          dap.adapters[adapter_name] = adapter_config
        end
        vim.notify("Loaded project DAP adapters: " .. vim.inspect(vim.tbl_keys(project_dap.adapters)), vim.log.levels.INFO)
      end
      
      -- Replace (not prepend) configurations for each language
      if project_dap.configurations then
        for lang, cfgs in pairs(project_dap.configurations) do
          dap.configurations[lang] = cfgs
        end
        vim.notify("Loaded project DAP config: " .. cwd .. "/.nvim-dap.lua", vim.log.levels.INFO)
        
        -- Print loaded configs
        for lang, cfgs in pairs(project_dap.configurations) do
          for _, cfg in ipairs(cfgs) do
            print("  [" .. lang .. "] " .. cfg.name)
          end
        end
      end
      
      return project_dap
    else
      vim.notify("Failed to load project DAP config: " .. project_config_path, vim.log.levels.WARN)
    end
  end
  return nil
end

-- Auto-load on directory change (optional)
function M.setup_autoload()
  vim.api.nvim_create_autocmd("DirChanged", {
    pattern = "*",
    callback = function()
      -- Small delay to let lazy-loading settle
      vim.defer_fn(M.load_project_dap, 100)
    end,
  })
  
  -- Also load on startup
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      vim.defer_fn(M.load_project_dap, 200)
    end,
  })
end

-- Command to manually reload project config
vim.api.nvim_create_user_command("DapLoadProject", function()
  M.load_project_dap()
end, { desc = "Load project-local .nvim-dap.lua" })

-- Keymap to run gdbserver in a new terminal
vim.keymap.set("n", "<leader>dg", function()
  local cwd = vim.fn.getcwd()
  local config_path = cwd .. "/.nvim-dap.lua"
  if vim.fn.filereadable(config_path) == 1 then
    local ok, config = pcall(dofile, config_path)
    if ok and config.gdbserver_cmd then
      vim.cmd("split | terminal " .. config.gdbserver_cmd)
    else
      vim.notify("No gdbserver_cmd in project .nvim-dap.lua", vim.log.levels.WARN)
    end
  else
    vim.notify("No project .nvim-dap.lua found", vim.log.levels.WARN)
  end
end, { desc = "DAP: Run gdbserver for project" })

-- Disassembly view (requires gdb DAP adapter with disassemble support)
vim.keymap.set("n", "<leader>dd", function()
  local s = require("dap").session()
  if not s then
    vim.notify("No active DAP session", vim.log.levels.WARN)
    return
  end
  local frame = s.current_frame
  if not frame or not frame.instructionPointerReference then
    vim.notify("No instruction pointer available", vim.log.levels.WARN)
    return
  end
  s:request("disassemble", {
    memoryReference = frame.instructionPointerReference,
    instructionCount = 30,
  }, function(err, response)
    if err then
      vim.notify("Disassemble error: " .. vim.inspect(err), vim.log.levels.ERROR)
      return
    end
    local lines = {}
    for _, insn in ipairs(response.instructions or {}) do
      local addr = insn.address or "?"
      local text = insn.instruction or insn.text or "?"
      table.insert(lines, string.format("%s: %s", addr, text))
    end
    -- Show in floating window
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    local width = math.min(100, vim.o.columns - 4)
    local height = math.min(#lines + 2, vim.o.lines - 4)
    local win = vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      width = width,
      height = height,
      col = (vim.o.columns - width) / 2,
      row = (vim.o.lines - height) / 2,
      style = "minimal",
      border = "rounded",
      title = " Disassembly ",
      title_pos = "center",
    })
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, nowait = true })
    vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf, nowait = true })
  end)
end, { desc = "DAP: Show disassembly at current PC" })

return M