return {
  "mingo99/verilog-autoinst.nvim",
  cmd = "AutoInst",
  dependencies = { "nvim-telescope/telescope.nvim" },
  keys = {
    {
      "<leader>vi",
      function()
        local bufnr = vim.api.nvim_get_current_buf()
        local start_line = vim.api.nvim_win_get_cursor(0)[1] -- 1-based
        local before_count = vim.api.nvim_buf_line_count(bufnr)

        local function get_line(lnum)
          return (vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or "")
        end

        local function leading_ws(s)
          return s:match("^%s*") or ""
        end

        local function sw()
          local s = vim.bo.shiftwidth
          if s == 0 then
            s = vim.bo.tabstop
          end
          return s
        end

        local function indent_string(cols)
          if cols <= 0 then
            return ""
          end
          if vim.bo.expandtab then
            return string.rep(" ", cols)
          else
            local step = sw()
            local tabs = math.floor(cols / step)
            local spaces = cols % step
            return string.rep("	", tabs) .. string.rep(" ", spaces)
          end
        end

        local function opens_block(line)
          line = line:gsub("//.*$", ""):gsub("/%*.*%*/", ""):gsub("%s+$", "")
          if line == "" then
            return false
          end

          if line:match("%f[%w](begin|case|fork|generate|class|function|task|module|interface|package|covergroup|clocking)%f[%W]%s*$") then
            return true
          end

          if line:match(":%s*begin%s*$") then
            return true
          end

          if line:match("^%s*[%w_]+%s*:%s*$") or line:match("^%s*default%s*:%s*$") then
            return true
          end

          if line:match("[%({]%s*$") then
            return true
          end

          return false
        end

        local function compute_base_indent(lnum)
          local cols = vim.fn.indent(lnum)
          if cols and cols > 0 then
            return indent_string(cols)
          end

          local prev = vim.fn.prevnonblank(lnum)
          if prev <= 0 then
            return ""
          end

          local pline = get_line(prev)
          local base = leading_ws(pline)
          if opens_block(pline) then
            base = base .. indent_string(sw())
          end

          return base
        end

        local base_indent = compute_base_indent(start_line)

        vim.cmd("AutoInst")

        vim.defer_fn(function()
          if not vim.api.nvim_buf_is_valid(bufnr) then
            return
          end

          local after_count = vim.api.nvim_buf_line_count(bufnr)
          local added = after_count - before_count
          if added <= 0 then
            return
          end

          local s = start_line
          local e = math.min(start_line + added, after_count)
          local lines = vim.api.nvim_buf_get_lines(bufnr, s - 1, e, false)

          for i, l in ipairs(lines) do
            if l ~= "" then
              lines[i] = base_indent .. l
            end
          end

          vim.api.nvim_buf_set_lines(bufnr, s - 1, e, false, lines)
        end, 200)
      end,
      desc = "SV: AutoInst (match nested-block indent)",
    },
  },
  opts = {
    fmt = true,
  },
}
