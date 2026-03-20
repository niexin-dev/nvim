-- 项目根目录辅助函数。
-- 1. 统一处理“给定文件路径后应该把 cwd 切到哪里”的逻辑。
-- 2. 共享给 dashboard、fzf-lua 等入口，避免同类路径判断散落在多个插件里。
local M = {}

local uv = vim.uv or vim.loop
local NO_GIT_ROOT = false
local dir_root_cache = {}
local file_root_cache = {}

function M.is_local_path(path)
	return type(path) == "string" and not path:match("^%w[%w+.-]*://")
end

function M.is_on_windows_mount(path)
	return type(path) == "string" and path:match("^/mnt/[a-zA-Z]/") ~= nil
end

function M.to_abs(path)
	if type(path) ~= "string" or path == "" then
		return ""
	end

	return vim.fn.fnamemodify(path, ":p") or ""
end

local function emit(opts, event)
	if opts and type(opts.on_event) == "function" then
		opts.on_event(event)
	end
end

function M.find_git_root(path, opts)
	if not path or path == "" then
		return nil
	end

	if not M.is_local_path(path) or M.is_on_windows_mount(path) then
		return nil
	end

	local abspath = M.to_abs(path)
	if abspath == "" then
		return nil
	end

	local cached_file = file_root_cache[abspath]
	if cached_file ~= nil then
		emit(opts, "file_hit")
		return cached_file or nil
	end

	local dir = (vim.fn.isdirectory(abspath) == 1) and abspath or vim.fn.fnamemodify(abspath, ":h")
	if dir == "" then
		file_root_cache[abspath] = NO_GIT_ROOT
		return nil
	end

	local visited = {}
	local cur = dir
	local root = nil

	while cur and cur ~= "" do
		local cached_dir = dir_root_cache[cur]
		if cached_dir ~= nil then
			emit(opts, "dir_hit")
			root = cached_dir ~= NO_GIT_ROOT and cached_dir or nil
			break
		end

		table.insert(visited, cur)
		emit(opts, "fs_check")
		if uv.fs_stat(cur .. "/.git") then
			root = cur
			break
		end

		local parent = vim.fn.fnamemodify(cur, ":h")
		if parent == cur then
			break
		end
		cur = parent
	end

	local cache_value = root or NO_GIT_ROOT
	for _, visited_dir in ipairs(visited) do
		dir_root_cache[visited_dir] = cache_value
	end

	file_root_cache[abspath] = cache_value
	return root
end

function M.resolve_context_dir(path, opts)
	if not path or path == "" then
		return nil
	end

	local abspath = M.to_abs(path)
	if abspath == "" then
		return nil
	end

	local dir = (vim.fn.isdirectory(abspath) == 1) and abspath or vim.fn.fnamemodify(abspath, ":h")
	if dir == "" or vim.fn.isdirectory(dir) == 0 then
		return nil
	end

	local git_root_finder = opts and opts.git_root_finder or M.find_git_root
	return git_root_finder(abspath, opts) or dir
end

function M.cd_to_path_context(path, opts)
	local target_dir = M.resolve_context_dir(path, opts)
	if not target_dir then
		return nil
	end

	vim.cmd("cd " .. vim.fn.fnameescape(target_dir))
	return target_dir
end

return M
