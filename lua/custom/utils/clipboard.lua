local M = {}

-- =========================
-- ENV DETECTION
-- =========================

local function is_ssh()
  return vim.env.SSH_CLIENT ~= nil or vim.env.SSH_TTY ~= nil
end

local function is_wsl()
  return vim.env.WSL_DISTRO_NAME ~= nil
end

local function is_windows()
  return vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
end

local function is_termux()
  return vim.fn.has("android") == 1
end

local function is_container()
  return vim.fn.filereadable("/.dockerenv") == 1
      or vim.fn.filereadable("/run/.containerenv") == 1
      or vim.fn.system("cat /proc/1/cgroup 2>/dev/null"):lower():find("docker") ~= nil
      or vim.fn.system("cat /proc/1/cgroup 2>/dev/null"):lower():find("podman") ~= nil
end

-- =========================
-- OSC52 (SSH SAFE COPY)
-- =========================

local function osc52_copy(lines, _)
  local text = table.concat(lines, "\n")

  local b64 = vim.fn.system("base64", text)
  b64 = b64:gsub("\n", "")

  local osc = "\27]52;c;" .. b64 .. "\7"
  io.stdout:write(osc)
  io.stdout:flush()
end

-- =========================
-- PROVIDERS
-- =========================

local function set_osc52()
  vim.g.clipboard = {
    name = "osc52",
    copy = {
      ["+"] = osc52_copy,
      ["*"] = osc52_copy,
    },
    paste = {
      ["+"] = function() return {} end,
      ["*"] = function() return {} end,
    },
  }
end

local function set_termux()
  vim.g.clipboard = {
    name = "termux",
    copy = {
      ["+"] = "termux-clipboard-set",
      ["*"] = "termux-clipboard-set",
    },
    paste = {
      ["+"] = "termux-clipboard-get",
      ["*"] = "termux-clipboard-get",
    },
    cache_enabled = 0,
  }
end

local function executable(cmd)
  return vim.fn.executable(cmd) == 1
end

local function set_wsl_container()
  if executable("clip.exe") then
    vim.g.clipboard = {
      name = "wsl-container-clip",
      copy = {
        ["+"] = "clip.exe",
        ["*"] = "clip.exe",
      },
      paste = {
        ["+"] = "powershell.exe -NoProfile -Command Get-Clipboard",
        ["*"] = "powershell.exe -NoProfile -Command Get-Clipboard",
      },
      cache_enabled = 0,
    }
  else
    -- fallback to OSC52 if Windows bridge not available
    set_osc52()
  end
end

local function set_wsl_native()
  vim.g.clipboard = {
    name = "wsl-native",
    copy = {
      ["+"] = "win32yank.exe -i --crlf",
      ["*"] = "win32yank.exe -i --crlf",
    },
    paste = {
      ["+"] = "win32yank.exe -o --lf",
      ["*"] = "win32yank.exe -o --lf",
    },
    cache_enabled = 0,
  }
end

local function set_windows()
  vim.g.clipboard = {
    name = "win32yank",
    copy = {
      ["+"] = "win32yank.exe -i --crlf",
      ["*"] = "win32yank.exe -i --crlf",
    },
    paste = {
      ["+"] = "win32yank.exe -o --lf",
      ["*"] = "win32yank.exe -o --lf",
    },
    cache_enabled = 0,
  }
end

local function set_linux()
  if vim.fn.executable("wl-copy") == 1 then
    vim.g.clipboard = {
      name = "wl-clipboard",
      copy = {
        ["+"] = "wl-copy",
        ["*"] = "wl-copy",
      },
      paste = {
        ["+"] = "wl-paste",
        ["*"] = "wl-paste",
      },
      cache_enabled = 0,
    }
  elseif vim.fn.executable("xclip") == 1 then
    vim.g.clipboard = {
      name = "xclip",
      copy = {
        ["+"] = "xclip -selection clipboard",
        ["*"] = "xclip -selection primary",
      },
      paste = {
        ["+"] = "xclip -selection clipboard -o",
        ["*"] = "xclip -selection primary -o",
      },
      cache_enabled = 0,
    }
  end
end

-- =========================
-- MAIN SWITCH
-- =========================

function M.setup()
  vim.schedule(function()

    -- 🌍 SSH ALWAYS wins
    if is_ssh() then
      set_osc52()

    -- 📱 Termux
    elseif is_termux() then
      set_termux()

    -- 🐧 WSL
    elseif is_wsl() then
      if is_container() then
        set_wsl_container()
      else
        set_wsl_native()
      end

    -- 🪟 Windows native
    elseif is_windows() then
      set_windows()

    -- 🐧 Linux
    else
      set_linux()
    end

    -- universal behavior
    -- vim.opt.clipboard = "unnamedplus"
  end)
end

return M
