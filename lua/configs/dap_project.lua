-- Project-local DAP configuration loader
-- Add to your global config (configs/dap.lua or plugins/dap.lua)

local M = {}

-- Load project-local .nvim-dap.lua if exists
function M.load_project_dap()
  local cwd = vim.fn.getcwd()
  local project_config_path = cwd .. "/.nvim-dap.lua"
  
  if vim.fn.filereadable(project_config_path) == 1 then
    local ok, project_dap = pcall(dofile, project_config_path)
    if ok and project_dap.configurations then
      local dap = require("dap")
      -- Replace (not prepend) configurations for each language
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

return M