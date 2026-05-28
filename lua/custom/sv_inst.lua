local M = {}

local function readfile(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local s = f:read("*a")
  f:close()
  return s
end

local function find_root()
  local cwd = vim.fn.getcwd()
  local root_marker = vim.fs.find({ "verible.filelist", ".git" }, { upward = true, path = cwd })[1]
  if root_marker then
    return vim.fs.dirname(root_marker)
  end
  return cwd
end

local function load_filelist(root)
  local p = root .. "/verible.filelist"
  local s = readfile(p)
  if not s then
    return nil
  end
  local files = {}
  for line in s:gmatch("[^\r\n]+") do
    line = line:gsub("^%s+", ""):gsub("%s+$", "")
    if line ~= "" then
      line = line:gsub("^%./", "")
      table.insert(files, root .. "/" .. line)
    end
  end
  return files
end

local function escape_lua_pattern(s)
  return (s:gsub("([^%w])", "%%%1"))
end

local function relpath_from(root, fullpath)
  root = vim.fs.normalize(root):gsub("/+$", "")
  fullpath = vim.fs.normalize(fullpath)
  local root_pat = "^" .. escape_lua_pattern(root) .. "/?"
  return fullpath:gsub(root_pat, "")
end

-- Split by commas, but only at top-level (ignore commas inside ()[]{} and strings)
local function split_top_commas(s)
  local out = {}
  local buf = {}
  local paren, brack, brace = 0, 0, 0
  local in_str = false
  local esc = false

  local function flush()
    local chunk = table.concat(buf):gsub("^%s+", ""):gsub("%s+$", "")
    if chunk ~= "" then
      table.insert(out, chunk)
    end
    buf = {}
  end

  for i = 1, #s do
    local c = s:sub(i, i)

    if in_str then
      table.insert(buf, c)
      if esc then
        esc = false
      elseif c == "\\" then
        esc = true
      elseif c == "\"" then
        in_str = false
      end
    else
      if c == "\"" then
        in_str = true
        table.insert(buf, c)
      elseif c == "(" then
        paren = paren + 1
        table.insert(buf, c)
      elseif c == ")" then
        paren = math.max(paren - 1, 0)
        table.insert(buf, c)
      elseif c == "[" then
        brack = brack + 1
        table.insert(buf, c)
      elseif c == "]" then
        brack = math.max(brack - 1, 0)
        table.insert(buf, c)
      elseif c == "{" then
        brace = brace + 1
        table.insert(buf, c)
      elseif c == "}" then
        brace = math.max(brace - 1, 0)
        table.insert(buf, c)
      elseif c == "," and paren == 0 and brack == 0 and brace == 0 then
        flush()
      else
        table.insert(buf, c)
      end
    end
  end

  flush()
  return out
end

-- Extract parameter {name, default_expr} from module header #(...)
-- default_expr is nil when no default exists
local function extract_params(modtext)
  local params = {}

  local hash_start = modtext:find("#%s*%(")
  if not hash_start then
    return params
  end

  local i = modtext:find("%(", hash_start)
  local depth = 0
  local j = i
  while j <= #modtext do
    local c = modtext:sub(j, j)
    if c == "(" then
      depth = depth + 1
    end
    if c == ")" then
      depth = depth - 1
      if depth == 0 then
        break
      end
    end
    j = j + 1
  end

  local block = modtext:sub(i + 1, j - 1)
  block = block:gsub("//[^\n]*", "")
  block = block:gsub("/%*.-%*/", "")

  local chunks = split_top_commas(block)

  for _, ch in ipairs(chunks) do
    if ch:match("%f[%w]parameter%f[%W]") then
      -- Greedy match: capture last identifier before '='
      local name, def = ch:match(".*([%a_][%w_]*)%s*=%s*(.+)$")
      if name and def then
        def = def:gsub("%s+$", "")
        table.insert(params, { name = name, default = def })
      else
        local n = ch:match("parameter%s+.-%s+([%a_][%w_]*)%s*$")
        if n then
          table.insert(params, { name = n, default = nil })
        end
      end
    end
  end

  return params
end

local function extract_ports(modtext)
  local ports = {}

  local after_mod = modtext:find("module%s")
  if not after_mod then
    return ports
  end

  local port_open
  local hash = modtext:find("#%s*%(")
  if hash then
    local i = modtext:find("%(", hash)
    local depth, j = 0, i
    while j <= #modtext do
      local c = modtext:sub(j, j)
      if c == "(" then
        depth = depth + 1
      end
      if c == ")" then
        depth = depth - 1
        if depth == 0 then
          break
        end
      end
      j = j + 1
    end
    port_open = modtext:find("%(", j + 1)
  else
    port_open = modtext:find("%(", after_mod)
  end

  if not port_open then
    return ports
  end

  local depth, j = 0, port_open
  while j <= #modtext do
    local c = modtext:sub(j, j)
    if c == "(" then
      depth = depth + 1
    end
    if c == ")" then
      depth = depth - 1
      if depth == 0 then
        break
      end
    end
    j = j + 1
  end

  local block = modtext:sub(port_open + 1, j - 1)
  block = block:gsub("//[^\n]*", "")
  block = block:gsub("/%*.-%*/", "")

  for decl in block:gmatch("[^,]+") do
    decl = decl:gsub("^%s+", ""):gsub("%s+$", "")
    local name = decl:match("([%a_][%w_]*)%s*(%[[^%]]+%])?%s*$")
    local dir = decl:match("^%s*(input|output|inout)%s+")
    if dir and name then
      table.insert(ports, name)
    end
  end

  return ports
end

local function find_module_file(root, modname)
  local files = load_filelist(root)
  if not files then
    return nil, "No verible.filelist found in project root; create one for reliable lookup."
  end

  local pat = "module%s+" .. modname .. "%f[%W]"
  for _, f in ipairs(files) do
    local s = readfile(f)
    if s and s:find(pat) then
      return f
    end
  end

  return nil, "Module '" .. modname .. "' not found in verible.filelist files."
end

function M.insert_instance(modname, instname)
  local root = find_root()
  local modfile, err = find_module_file(root, modname)
  if not modfile then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  local modrel = relpath_from(root, modfile)
  local modtext = readfile(modfile)
  if not modtext then
    vim.notify("Failed to read module file: " .. modfile, vim.log.levels.ERROR)
    return
  end

  local params = extract_params(modtext)
  local ports = extract_ports(modtext)

  local out = {}

  -- Always emit explicit #(...)
  table.insert(out, modname .. " #(")
  if #params == 0 then
    table.insert(out, "  // (no parameters found)")
  else
    for k, p in ipairs(params) do
      local comma = (k == #params) and "" or ","
      local rhs
      if p.default and p.default ~= "" then
        rhs = p.default
      else
        rhs = string.format("<TODO:%s:%s.%s@%s>", instname, modname, p.name, modrel)
      end
      table.insert(out, "  ." .. p.name .. "(" .. rhs .. ")" .. comma)
    end
  end
  table.insert(out, ") " .. instname .. " (")

  if #ports == 0 then
    table.insert(out, "  // (no ports found)")
  else
    for i, p in ipairs(ports) do
      local comma = (i == #ports) and "" or ","
      table.insert(out, "  ." .. p .. "(" .. p .. ")" .. comma)
    end
  end

  table.insert(out, ");")

  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row, row, false, out)

  vim.notify("Inserted instance for " .. modname .. " from " .. modrel)
end

function M.setup()
  vim.api.nvim_create_user_command("SvInst", function(opts)
    local args = vim.split(opts.args, "%s+")
    if #args < 2 then
      vim.notify("Usage: :SvInst <module_name> <instance_name>", vim.log.levels.ERROR)
      return
    end
    M.insert_instance(args[1], args[2])
  end, { nargs = "+" })
end

return M
