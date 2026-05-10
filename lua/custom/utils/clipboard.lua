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

local function executable(cmd)
  return vim.fn.executable(cmd) == 1
end

-- =========================
-- OSC52 (NATIVE, COPY-ONLY SAFE DEFAULT)
-- =========================
-- Many terminals support OSC52 copy but do NOT support clipboard readback.
-- To avoid hangs/timeouts, we implement a "safe paste" that pastes from the unnamed register.
-- (You can still paste from system clipboard with your terminal shortcut, e.g. Ctrl+Shift+V.)
local function safe_paste()
  return { vim.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
end

local function set_osc52()
  local ok, osc52 = pcall(require, "vim.ui.clipboard.osc52")
  if not ok then
    -- Very unlikely on nvim 0.12, but keep a minimal fallback:
    -- (No OSC52 provider available -> do nothing)
    return
  end

  vim.g.clipboard = {
    name = "osc52-native",
    copy = {
      ["+"] = osc52.copy("+"),
      ["*"] = osc52.copy("*"),
    },
    -- IMPORTANT: avoid OSC52 paste/readback to prevent terminal timeouts/freezes
    -- See common reports of "Waiting for OSC 52 response..." in terminals. [3](https://github.com/neovim/neovim/discussions/28010)
    paste = {
      ["+"] = safe_paste,
      ["*"] = safe_paste,
    },
  }
end

-- =========================
-- PROVIDERS
-- =========================
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

local function set_wsl_container()
  -- In containers, WSL interop is commonly unavailable even if WSL vars exist.
  -- If WSL_INTEROP is missing, Windows clipboard bridge tools tend to fail -> use OSC52.
  if not vim.env.WSL_INTEROP or vim.env.WSL_INTEROP == "" then
    set_osc52()
    return
  end

  -- If interop is present, try the Windows bridge.
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
    set_osc52()
  end
end

local function set_wsl_native()
  -- Prefer win32yank if available, otherwise clip.exe, otherwise OSC52.
  if executable("win32yank.exe") then
    vim.g.clipboard = {
      name = "wsl-win32yank",
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
  elseif executable("clip.exe") then
    vim.g.clipboard = {
      name = "wsl-clip",
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
    set_osc52()
  end
end

local function set_windows()
  if executable("win32yank.exe") then
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
  else
    -- Fallback on pure Windows machines
    vim.g.clipboard = {
      name = "powershell-clipboard",
      copy = {
        ["+"] = "powershell.exe -NoProfile -Command Set-Clipboard",
        ["*"] = "powershell.exe -NoProfile -Command Set-Clipboard",
      },
      paste = {
        ["+"] = "powershell.exe -NoProfile -Command Get-Clipboard",
        ["*"] = "powershell.exe -NoProfile -Command Get-Clipboard",
      },
      cache_enabled = 0,
    }
  end
end

local function set_linux()
  if executable("wl-copy") then
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
  elseif executable("xclip") then
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
  else
    -- Last resort: OSC52 still allows copy-out from remote/container contexts
    set_osc52()
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

    -- If you want normal `y` to go to system clipboard automatically, enable this:
    -- vim.opt.clipboard = "unnamedplus"
  end)
end

return M
