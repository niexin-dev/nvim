-- 本地启动面板。
-- 1. 目标不是“炫酷欢迎页”，而是把最近文件按项目根聚合，缩短进入工作上下文的路径。
-- 2. 主入口只负责组装共享上下文；项目根、oldfiles、UI 渲染分别拆到独立模块。
-- 3. 你的工作流是“先开 nvim，再从 dashboard 进项目”，因此这里保留了全局 cwd 切换设计。
local M = {}

local defaults = {
  use_icons = true,
  max_roots = 10,
  per_root_files = 5,
  max_oldfiles_scan = 100,

  preheat_git_root = true,
  preheat_git_root_max = 200,
  preheat_git_root_batch = 50,

  debug = false,

  map_open = "<leader>fd",
  auto_open_on_uienter = true,

  cmd_open = "NxDashboard",
  cmd_stats = "NxDashboardStats",
  cmd_debug_toggle = "NxDashboardDebugToggle",
}

local function create_context(opts)
  local api = vim.api
  local fn = vim.fn
  local uv = vim.loop
  local O = vim.tbl_deep_extend("force", {}, defaults, opts or {})

  local ctx = {
    api = api,
    fn = fn,
    uv = uv,
    O = O,
    project_root = require("config.project_root"),

    USE_ICONS = O.use_icons,
    MAX_ROOTS = O.max_roots,
    PER_ROOT_FILES = O.per_root_files,
    MAX_OLDFILES_SCAN = O.max_oldfiles_scan,
    PREHEAT_GIT_ROOT = O.preheat_git_root,
    PREHEAT_GIT_ROOT_MAX = O.preheat_git_root_max,
    PREHEAT_GIT_ROOT_BATCH = O.preheat_git_root_batch,

    debug = O.debug,
    expanded_root = nil,
    pending_cursor = nil,
    startup_cwd = fn.getcwd(),
    dashboard_buf = nil,
    ns_dashboard = api.nvim_create_namespace("NxDashboard"),

    stats = {
      renders = 0,
      render_ms_total = 0,
      oldfiles_sig_changes = 0,
      oldfiles_top_builds = 0,
      oldfiles_all_builds = 0,
      oldfiles_top_ms_total = 0,
      oldfiles_all_ms_total = 0,
      git_root_calls = 0,
      git_root_file_hit = 0,
      git_root_dir_hit = 0,
      git_root_fs_checks = 0,
      git_root_ms_total = 0,
      preheat_runs = 0,
      preheat_git_root_runs = 0,
      abs_cache_hit = 0,
      abs_cache_miss = 0,
    },
  }

  function ctx.now_ms()
    return uv.hrtime() / 1e6
  end

  function ctx.dbg(msg)
    if not ctx.debug then
      return
    end
    vim.schedule(function()
      vim.notify(msg, vim.log.levels.INFO, { title = "nx-dashboard" })
    end)
  end

  function ctx.print_stats()
    local stats = ctx.stats
    local avg_render = stats.renders > 0 and (stats.render_ms_total / stats.renders) or 0
    local avg_git = stats.git_root_calls > 0 and (stats.git_root_ms_total / stats.git_root_calls) or 0

    local msg = table.concat({
      ("renders=%d, render_total=%.1fms, render_avg=%.2fms"):format(stats.renders, stats.render_ms_total, avg_render),
      ("oldfiles_sig_changes=%d"):format(stats.oldfiles_sig_changes),
      ("oldfiles_top_builds=%d, top_total=%.1fms"):format(stats.oldfiles_top_builds, stats.oldfiles_top_ms_total),
      ("oldfiles_all_builds=%d, all_total=%.1fms"):format(stats.oldfiles_all_builds, stats.oldfiles_all_ms_total),
      ("git_root_calls=%d, git_total=%.1fms, git_avg=%.3fms"):format(stats.git_root_calls, stats.git_root_ms_total, avg_git),
      ("git_cache_hit_file=%d, git_cache_hit_dir=%d, git_fs_checks=%d"):format(
        stats.git_root_file_hit,
        stats.git_root_dir_hit,
        stats.git_root_fs_checks
      ),
      ("preheat_runs=%d, preheat_git_root_runs=%d"):format(stats.preheat_runs, stats.preheat_git_root_runs),
      ("abs_cache_hit=%d, abs_cache_miss=%d"):format(stats.abs_cache_hit, stats.abs_cache_miss),
    }, "\n")

    vim.notify(msg, vim.log.levels.INFO, { title = "nx-dashboard stats" })
  end

  return ctx
end

function M.setup(opts)
  local ctx = create_context(opts)

  require("nx-dashboard.roots").attach(ctx)
  require("nx-dashboard.oldfiles").attach(ctx)
  require("nx-dashboard.ui").attach(ctx)

  ctx.register_commands()
end

return M
