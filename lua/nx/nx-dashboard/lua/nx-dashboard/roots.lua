local M = {}

function M.attach(ctx)
  local fn = ctx.fn
  local project_root = ctx.project_root
  local stats = ctx.stats

  local abs_cache = {}
  local root_prefix_cache = {}

  local function looks_abs_clean(path)
    return type(path) == "string"
      and path:sub(1, 1) == "/"
      and not path:find("/%./")
      and not path:find("/%.%./")
      and not path:find("//")
  end

  local function to_abs(path)
    if not path or path == "" then
      return ""
    end

    local cached = abs_cache[path]
    if cached ~= nil then
      stats.abs_cache_hit = stats.abs_cache_hit + 1
      return cached
    end

    stats.abs_cache_miss = stats.abs_cache_miss + 1

    local abs
    if looks_abs_clean(path) then
      abs = path
    else
      abs = fn.fnamemodify(path, ":p")
    end

    abs = abs or ""
    abs_cache[path] = abs
    return abs
  end

  local function root_prefix(root_key)
    if root_key == "OTHER" or not root_key or root_key == "" then
      return nil
    end

    local cached = root_prefix_cache[root_key]
    if cached ~= nil then
      return cached or nil
    end

    local abs = to_abs(root_key)
    if abs == "" then
      root_prefix_cache[root_key] = false
      return nil
    end

    if not abs:match("/$") then
      abs = abs .. "/"
    end

    root_prefix_cache[root_key] = abs
    return abs
  end

  local function find_git_root(path)
    stats.git_root_calls = stats.git_root_calls + 1
    local t0 = ctx.now_ms()

    local root = project_root.find_git_root(path, {
      on_event = function(event)
        if event == "file_hit" then
          stats.git_root_file_hit = stats.git_root_file_hit + 1
        elseif event == "dir_hit" then
          stats.git_root_dir_hit = stats.git_root_dir_hit + 1
        elseif event == "fs_check" then
          stats.git_root_fs_checks = stats.git_root_fs_checks + 1
        end
      end,
    })

    stats.git_root_ms_total = stats.git_root_ms_total + (ctx.now_ms() - t0)
    return root
  end

  local function display_path_for_root(root_key, fname)
    local abs = to_abs(fname)
    if abs == "" then
      return fn.fnamemodify(fname, ":~:.")
    end

    if root_key == "OTHER" then
      return fn.fnamemodify(abs, ":~:.")
    end

    local prefix = root_prefix(root_key)
    if not prefix then
      return fn.fnamemodify(abs, ":~:.")
    end

    if abs:sub(1, #prefix) == prefix then
      local rel = abs:sub(#prefix + 1)
      return rel ~= "" and rel or "."
    end

    return fn.fnamemodify(abs, ":~:.")
  end

  local function group_files_by_root(files)
    local grouped = {}
    local order = {}
    local per_root_count = {}

    local expanded_prefix = nil
    if ctx.expanded_root and ctx.expanded_root ~= "OTHER" then
      expanded_prefix = root_prefix(ctx.expanded_root)
    end

    for _, fname in ipairs(files) do
      local abspath = to_abs(fname)
      if abspath ~= "" then
        local key
        if expanded_prefix and abspath:sub(1, #expanded_prefix) == expanded_prefix then
          key = ctx.expanded_root
          project_root.remember_file_root(abspath, ctx.expanded_root)
        else
          key = find_git_root(abspath) or "OTHER"
        end

        local can_use_group = grouped[key] ~= nil
        if not can_use_group then
          local reached = (#order >= ctx.MAX_ROOTS)
          local must_keep = (ctx.expanded_root ~= nil and key == ctx.expanded_root)
          can_use_group = not reached or must_keep
          if can_use_group then
            grouped[key] = {}
            per_root_count[key] = 0
            table.insert(order, key)
          end
        end

        if can_use_group then
          local limit = (ctx.expanded_root ~= nil and key == ctx.expanded_root) and math.huge or ctx.PER_ROOT_FILES
          if per_root_count[key] < limit then
            table.insert(grouped[key], abspath)
            per_root_count[key] = per_root_count[key] + 1
          end
        end
      end
    end

    local cwd_root = find_git_root(ctx.startup_cwd)
    if cwd_root then
      local cwd_root_abs = to_abs(cwd_root)
      local matched
      for _, key in ipairs(order) do
        if key ~= "OTHER" and to_abs(key) == cwd_root_abs then
          matched = key
          break
        end
      end
      if matched then
        local new_order = { matched }
        for _, key in ipairs(order) do
          if key ~= matched then
            table.insert(new_order, key)
          end
        end
        order = new_order
      end
    end

    return grouped, order
  end

  ctx.is_local_path = project_root.is_local_path
  ctx.is_on_windows_mount = project_root.is_on_windows_mount
  ctx.to_abs = to_abs
  ctx.root_prefix = root_prefix
  ctx.find_git_root = find_git_root
  ctx.display_path_for_root = display_path_for_root
  ctx.group_files_by_root = group_files_by_root
  ctx.reset_path_caches = function()
    abs_cache = {}
    root_prefix_cache = {}
  end
end

return M
