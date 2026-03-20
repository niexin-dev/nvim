local M = {}

function M.attach(ctx)
  local fn = ctx.fn
  local stats = ctx.stats

  local oldfiles_cache_top = nil
  local oldfiles_cache_all = nil
  local oldfiles_sig_cached = nil
  local preheat_scheduled = false

  local function oldfiles_signature(list)
    if type(list) ~= "table" then
      return "nil"
    end

    local n = #list
    if n == 0 then
      return "0"
    end

    local function at(index)
      local value = list[index]
      return value or ""
    end

    local mid = math.floor(n / 2)
    return table.concat({
      tostring(n),
      at(1),
      at(2),
      at(3),
      at(mid),
      at(n - 2),
      at(n - 1),
      at(n),
    }, "\n")
  end

  local function invalidate_oldfiles_cache_if_needed()
    local sig = oldfiles_signature(vim.v.oldfiles or {})
    if sig ~= oldfiles_sig_cached then
      oldfiles_sig_cached = sig
      oldfiles_cache_top = nil
      oldfiles_cache_all = nil
      preheat_scheduled = false
      stats.oldfiles_sig_changes = stats.oldfiles_sig_changes + 1

      ctx.reset_path_caches()
      ctx.dbg("oldfiles changed: caches invalidated")
    end
  end

  local function get_valid_oldfiles_cached(scan_all)
    invalidate_oldfiles_cache_if_needed()

    if scan_all then
      if oldfiles_cache_all ~= nil then
        return oldfiles_cache_all
      end
    elseif oldfiles_cache_top ~= nil then
      return oldfiles_cache_top
    end

    local t0 = ctx.now_ms()
    local result = {}
    local count = 0

    for _, fname in ipairs(vim.v.oldfiles or {}) do
      count = count + 1
      if (not scan_all) and count > ctx.MAX_OLDFILES_SCAN then
        break
      end

      if ctx.is_local_path(fname) and not ctx.is_on_windows_mount(fname) and fn.filereadable(fname) == 1 then
        table.insert(result, fname)
      end
    end

    local dt = ctx.now_ms() - t0
    if scan_all then
      oldfiles_cache_all = result
      stats.oldfiles_all_builds = stats.oldfiles_all_builds + 1
      stats.oldfiles_all_ms_total = stats.oldfiles_all_ms_total + dt
    else
      oldfiles_cache_top = result
      stats.oldfiles_top_builds = stats.oldfiles_top_builds + 1
      stats.oldfiles_top_ms_total = stats.oldfiles_top_ms_total + dt
    end

    return result
  end

  local function preheat_git_roots_batch(files)
    if not ctx.PREHEAT_GIT_ROOT then
      return
    end
    if type(files) ~= "table" or #files == 0 then
      return
    end

    stats.preheat_git_root_runs = stats.preheat_git_root_runs + 1

    local maxn = math.min(#files, ctx.PREHEAT_GIT_ROOT_MAX)
    local index = 1

    local function step()
      local end_index = math.min(index + ctx.PREHEAT_GIT_ROOT_BATCH - 1, maxn)
      for j = index, end_index do
        ctx.find_git_root(files[j])
      end
      index = end_index + 1
      if index <= maxn then
        vim.schedule(step)
      end
    end

    vim.schedule(step)
  end

  local function schedule_preheat_all_oldfiles()
    invalidate_oldfiles_cache_if_needed()

    if oldfiles_cache_all ~= nil or preheat_scheduled then
      return
    end

    preheat_scheduled = true
    stats.preheat_runs = stats.preheat_runs + 1

    vim.schedule(function()
      invalidate_oldfiles_cache_if_needed()
      if oldfiles_cache_all ~= nil then
        return
      end

      local ok = pcall(function()
        get_valid_oldfiles_cached(true)
      end)
      if not ok then
        return
      end

      preheat_git_roots_batch(oldfiles_cache_all)
      ctx.dbg(("preheat done: all_oldfiles=%d, preheat_git_root=%s"):format(
        oldfiles_cache_all and #oldfiles_cache_all or 0,
        tostring(ctx.PREHEAT_GIT_ROOT)
      ))
    end)
  end

  ctx.get_valid_oldfiles_cached = get_valid_oldfiles_cached
  ctx.schedule_preheat_all_oldfiles = schedule_preheat_all_oldfiles
end

return M
