local M = {}

local HEADER = {
  [[    _   _   _                 _           _           _   _                          _                ]],
  [[   | \ | | (_)   ___  __  __ (_)  _ __   ( )  ___    | \ | |   ___    ___   __   __ (_)  _ __ ___     ]],
  [[   |  \| | | |  / _ \ \ \/ / | | | '_ \  |/  / __|   |  \| |  / _ \  / _ \  \ \ / / | | | '_ ` _ \    ]],
  [[   | |\  | | | |  __/  >  <  | | | | | |     \__ \   | |\  | |  __/ | (_) |  \ V /  | | | | | | | |   ]],
  [[   |_| \_| |_|  \___| /_/\_\ |_| |_| |_|     |___/   |_| \_|  \___|  \___/    \_/   |_| |_| |_| |_|   ]],
}

function M.attach(ctx)
  local api = ctx.api
  local fn = ctx.fn
  local project_root = ctx.project_root

  local has_devicons, devicons = false, nil
  if ctx.USE_ICONS then
    has_devicons, devicons = pcall(require, "nvim-web-devicons")
  end

  local ok_colors, tn_colors = pcall(function()
    return require("tokyonight.colors").setup()
  end)

  local colors = ok_colors and tn_colors
    or {
      magenta = "#ff79c6",
      blue = "#61afef",
      orange = "#d19a66",
      cyan = "#56b6c2",
      comment = "#5c6370",
    }

  local function setup_hl()
    local hl = {
      OldfilesHeader = { fg = colors.magenta, bold = true },
      OldfilesSection = { fg = colors.blue, bold = true },
      OldfilesIndex = { fg = colors.orange, bold = true },
      OldfilesPath = { fg = colors.comment, italic = true },
      OldfilesFilename = { fg = colors.cyan, bold = true },
      OldfilesHint = { fg = colors.comment, italic = true },
    }
    for key, value in pairs(hl) do
      api.nvim_set_hl(0, key, value)
    end
  end

  setup_hl()
  api.nvim_create_autocmd("ColorScheme", { callback = setup_hl })

  local icon_cache = {}

  local function get_icon_cached(fname)
    if not ctx.USE_ICONS then
      return "", nil
    end
    if not has_devicons or type(devicons) ~= "table" or type(devicons.get_icon) ~= "function" then
      return "", nil
    end

    local cached = icon_cache[fname]
    if cached then
      return cached.icon, cached.hl
    end

    local ext = fn.fnamemodify(fname, ":e")
    local icon, hl = devicons.get_icon(fname, ext, { default = true })
    icon_cache[fname] = { icon = icon or "", hl = hl or nil }
    return icon_cache[fname].icon, icon_cache[fname].hl
  end

  local function get_current_file_under_cursor()
    if not ctx.dashboard_buf or not api.nvim_buf_is_valid(ctx.dashboard_buf) then
      return nil
    end

    local cur_line = api.nvim_win_get_cursor(0)[1]
    local ok_groups, cur_groups = pcall(api.nvim_buf_get_var, ctx.dashboard_buf, "startup_groups")
    if not ok_groups or not cur_groups then
      return nil
    end

    for _, group in ipairs(cur_groups) do
      for _, entry in ipairs(group.files) do
        if entry.lnum == cur_line then
          return entry.raw
        end
      end
    end

    return nil
  end

  local function restore_cursor_to_root(win, groups, root, prefer_path)
    if not root or not groups then
      return
    end

    if prefer_path then
      local prefer_abs = ctx.to_abs(prefer_path)
      for _, group in ipairs(groups) do
        if group.key == root then
          for _, entry in ipairs(group.files) do
            if ctx.to_abs(entry.raw) == prefer_abs then
              api.nvim_win_set_cursor(win, { entry.lnum, entry.ps or 0 })
              return
            end
          end
        end
      end
    end

    for _, group in ipairs(groups) do
      if group.key == root and #group.files > 0 then
        api.nvim_win_set_cursor(win, { group.files[1].lnum, group.files[1].ps or 0 })
        return
      end
    end
  end

  local function open_oldfile(path)
    if not path or path == "" or not ctx.is_local_path(path) then
      return
    end

    local abspath = ctx.to_abs(path)
    if abspath == "" then
      return
    end

    local dir = fn.fnamemodify(abspath, ":h")
    if dir == "" or fn.isdirectory(dir) == 0 then
      vim.cmd.edit(fn.fnameescape(abspath))
      return
    end

    -- 有意切换全局 cwd，让后续项目级命令直接落在当前文件所属项目根目录。
    project_root.cd_to_path_context(abspath, { git_root_finder = ctx.find_git_root })
    vim.cmd.edit(fn.fnameescape(abspath))
  end

  local function move_delta(delta)
    if not ctx.dashboard_buf or not api.nvim_buf_is_valid(ctx.dashboard_buf) then
      return
    end

    local ok_entries, entries = pcall(api.nvim_buf_get_var, ctx.dashboard_buf, "startup_entries")
    if not ok_entries or not entries or #entries == 0 then
      return
    end

    local cur_line = api.nvim_win_get_cursor(0)[1]
    local cur_idx
    for index, entry in ipairs(entries) do
      if entry.lnum == cur_line then
        cur_idx = index
        break
      end
    end

    local total = #entries
    if not cur_idx then
      cur_idx = (delta > 0) and 1 or total
    elseif delta > 0 then
      cur_idx = (cur_idx % total) + 1
    else
      cur_idx = (cur_idx - 2 + total) % total + 1
    end

    local entry = entries[cur_idx]
    api.nvim_win_set_cursor(0, { entry.lnum, entry.ps or 0 })
  end

  local function ensure_dashboard_buf()
    if ctx.dashboard_buf and api.nvim_buf_is_valid(ctx.dashboard_buf) then
      return ctx.dashboard_buf
    end

    ctx.dashboard_buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_name(ctx.dashboard_buf, "nx-dashboard")
    api.nvim_set_option_value("buftype", "nofile", { buf = ctx.dashboard_buf })
    api.nvim_set_option_value("bufhidden", "wipe", { buf = ctx.dashboard_buf })
    api.nvim_set_option_value("swapfile", false, { buf = ctx.dashboard_buf })
    api.nvim_set_option_value("filetype", "dashboard", { buf = ctx.dashboard_buf })

    local function map(lhs, rhs)
      vim.keymap.set("n", lhs, rhs, { buffer = ctx.dashboard_buf, silent = true })
    end

    for _, key in ipairs({ "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" }) do
      map(key, function()
        local index = (key == "0") and 10 or tonumber(key)
        local ok_groups, groups = pcall(api.nvim_buf_get_var, ctx.dashboard_buf, "startup_groups")
        if not ok_groups or not groups then
          return
        end

        local group = groups[index]
        if not group then
          return
        end

        local cur_path = get_current_file_under_cursor()
        ctx.pending_cursor = { root = group.key, path = cur_path }

        if ctx.expanded_root == group.key then
          ctx.expanded_root = nil
          vim.cmd(ctx.O.cmd_open)
          return
        end

        ctx.expanded_root = group.key
        if group.key ~= "OTHER" then
          -- 数字键展开项目时，同步切全局 cwd，确保后续搜索 / Git / 终端都落在同一项目根。
          vim.cmd("cd " .. fn.fnameescape(group.key))
        end
        vim.cmd(ctx.O.cmd_open)
      end)
    end

    map("<CR>", function()
      local cur_line = api.nvim_win_get_cursor(0)[1]
      local ok_groups, groups = pcall(api.nvim_buf_get_var, ctx.dashboard_buf, "startup_groups")
      if not ok_groups or not groups then
        return
      end
      for _, group in ipairs(groups) do
        for _, entry in ipairs(group.files) do
          if entry.lnum == cur_line then
            open_oldfile(entry.raw)
            return
          end
        end
      end
    end)

    map("j", function() move_delta(1) end)
    map("k", function() move_delta(-1) end)

    for _, key in ipairs({ "<Esc>", "q" }) do
      map(key, "<cmd>bd!<cr>")
    end

    local function map_pass(key)
      map(key, function()
        local seq = ((vim.v.count > 0) and tostring(vim.v.count) or "") .. key
        vim.cmd("bd!")
        local term = api.nvim_replace_termcodes(seq, true, false, true)
        api.nvim_feedkeys(term, "n", false)
      end)
    end

    for _, key in ipairs({ "i", "I", "a", "A", "o", "O", "s", "S", "c", "C", "r", "R" }) do
      map_pass(key)
    end

    return ctx.dashboard_buf
  end

  local function render()
    ctx.stats.renders = ctx.stats.renders + 1
    local t0 = ctx.now_ms()

    local buf = ensure_dashboard_buf()
    api.nvim_win_set_buf(0, buf)
    api.nvim_buf_clear_namespace(buf, ctx.ns_dashboard, 0, -1)

    local lines = {}
    for _, line in ipairs(HEADER) do
      table.insert(lines, line)
    end
    table.insert(lines, "")

    local section_lnum = #lines + 1
    if ctx.expanded_root ~= nil then
      local show = (ctx.expanded_root == "OTHER") and "Other files" or fn.fnamemodify(ctx.expanded_root, ":~:.")
      table.insert(lines, ("    Recent projects (expanded: %s)"):format(show))
    else
      table.insert(lines, "    Recent projects (by git root)")
    end
    table.insert(lines, "  " .. string.rep("─", math.min(vim.o.columns - 4, 50)))
    table.insert(lines, "")

    local valid_files = ctx.get_valid_oldfiles_cached(ctx.expanded_root ~= nil)
    local grouped, order = ctx.group_files_by_root(valid_files)

    local groups = {}
    local group_header_lnums = {}
    local group_index = 0

    for _, root_key in ipairs(order) do
      local files = grouped[root_key]
      if files and #files > 0 then
        group_index = group_index + 1
        local label = (group_index == 10) and "0" or tostring(group_index)

        local root_name = (root_key == "OTHER") and "Other files" or fn.fnamemodify(root_key, ":~:.")
        local title
        if root_key == "OTHER" then
          title = string.format("  [%s]    %s", label, root_name)
        else
          title = string.format("  [%s]    %s", label, root_name)
        end
        if ctx.expanded_root ~= nil and root_key == ctx.expanded_root then
          title = title .. "  (expanded)"
        end

        local group_lnum = #lines + 1
        table.insert(lines, title)
        table.insert(group_header_lnums, group_lnum)

        local group = { key = root_key, index = group_index, header_lnum = group_lnum, files = {} }

        for _, abspath in ipairs(files) do
          local path = ctx.display_path_for_root(root_key, abspath)
          local icon, icon_hl = get_icon_cached(abspath)
          local prefix = "      "
          local icon_part = (ctx.USE_ICONS and icon ~= "") and (icon .. " ") or ""
          local full_line = prefix .. icon_part .. path
          table.insert(lines, full_line)

          local lnum = #lines
          table.insert(group.files, {
            lnum = lnum,
            ps = #prefix + #icon_part,
            raw = abspath,
            icon = icon,
            icon_col = #prefix,
            icon_hl = icon_hl,
          })
        end

        table.insert(lines, "")
        table.insert(groups, group)
      end
    end

    if #groups == 0 then
      table.insert(lines, "  (no recent git projects)")
    end

    table.insert(lines, "")
    local hint_lnum = #lines + 1
    table.insert(lines, "    [0-9] Expand/Collapse · j/k Move · <CR> Open file · <Esc>/q Close")

    api.nvim_set_option_value("modifiable", true, { buf = buf })
    api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    api.nvim_set_option_value("modifiable", false, { buf = buf })

    api.nvim_buf_set_var(buf, "startup_groups", groups)

    local entries = {}
    for _, group in ipairs(groups) do
      for _, entry in ipairs(group.files) do
        table.insert(entries, entry)
      end
    end
    api.nvim_buf_set_var(buf, "startup_entries", entries)

    for i = 0, #HEADER - 1 do
      api.nvim_buf_add_highlight(buf, ctx.ns_dashboard, "OldfilesHeader", i, 0, -1)
    end
    api.nvim_buf_add_highlight(buf, ctx.ns_dashboard, "OldfilesSection", section_lnum - 1, 0, -1)
    api.nvim_buf_add_highlight(buf, ctx.ns_dashboard, "OldfilesHint", hint_lnum - 1, 0, -1)

    for _, lnum in ipairs(group_header_lnums) do
      api.nvim_buf_add_highlight(buf, ctx.ns_dashboard, "OldfilesSection", lnum - 1, 0, -1)
      api.nvim_buf_add_highlight(buf, ctx.ns_dashboard, "OldfilesIndex", lnum - 1, 2, 5)
    end

    for _, group in ipairs(groups) do
      for _, entry in ipairs(group.files) do
        local l0 = entry.lnum - 1
        local line = lines[entry.lnum]
        local last_slash = line:match(".*()/")

        if last_slash and last_slash >= entry.ps then
          api.nvim_buf_add_highlight(buf, ctx.ns_dashboard, "OldfilesPath", l0, entry.ps, last_slash)
          api.nvim_buf_add_highlight(buf, ctx.ns_dashboard, "OldfilesFilename", l0, last_slash, -1)
        else
          api.nvim_buf_add_highlight(buf, ctx.ns_dashboard, "OldfilesFilename", l0, entry.ps, -1)
        end

        if ctx.USE_ICONS and entry.icon ~= "" and entry.icon_hl then
          api.nvim_buf_set_extmark(buf, ctx.ns_dashboard, l0, entry.icon_col, {
            virt_text = { { entry.icon, entry.icon_hl } },
            virt_text_pos = "overlay",
            virt_text_hide = true,
          })
        end
      end
    end

    if ctx.pending_cursor ~= nil then
      restore_cursor_to_root(0, groups, ctx.pending_cursor.root, ctx.pending_cursor.path)
      ctx.pending_cursor = nil
    else
      for _, group in ipairs(groups) do
        if #group.files > 0 then
          api.nvim_win_set_cursor(0, { group.files[1].lnum, group.files[1].ps or 0 })
          break
        end
      end
    end

    if ctx.expanded_root == nil then
      ctx.schedule_preheat_all_oldfiles()
    end

    local dt = ctx.now_ms() - t0
    ctx.stats.render_ms_total = ctx.stats.render_ms_total + dt
    ctx.dbg(("render: expanded=%s, dt=%.2fms"):format(tostring(ctx.expanded_root), dt))
  end

  ctx.render = render
  ctx.register_commands = function()
    api.nvim_create_user_command(ctx.O.cmd_open, function() render() end, { desc = "Open startup dashboard" })
    api.nvim_create_user_command(ctx.O.cmd_stats, function() ctx.print_stats() end, { desc = "Show dashboard profiling stats" })
    api.nvim_create_user_command(ctx.O.cmd_debug_toggle, function()
      ctx.debug = not ctx.debug
      vim.notify(("nx-dashboard DEBUG=%s"):format(tostring(ctx.debug)), vim.log.levels.INFO, { title = "nx-dashboard" })
    end, { desc = "Toggle dashboard debug logs" })

    if ctx.O.map_open and ctx.O.map_open ~= "" then
      vim.keymap.set("n", ctx.O.map_open, ("<cmd>%s<CR>"):format(ctx.O.cmd_open), { desc = "Open startup dashboard" })
    end

    if ctx.O.auto_open_on_uienter then
      local function maybe_render_on_startup()
        if fn.argc() == 0 and api.nvim_buf_get_name(0) == "" then
          render()
        end
      end

      if #api.nvim_list_uis() > 0 then
        -- 插件本身现在也是 UIEnter 懒加载，这里要兼容“加载时 UI 已经存在”的场景。
        vim.schedule(maybe_render_on_startup)
      else
        api.nvim_create_autocmd("UIEnter", {
          once = true,
          callback = maybe_render_on_startup,
        })
      end
    end
  end
end

return M
