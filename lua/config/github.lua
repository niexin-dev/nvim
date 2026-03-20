-- GitHub 访问策略。
-- 1. 默认统一走代理，避免在网络不稳定时让 GitHub 相关操作各自失败。
-- 2. 可通过环境变量覆盖：
--    - GITHUB_PROXY_MODE=proxy|direct|auto
--    - GITHUB_PROXY_BASE=https://ghfast.top/https://github.com/
local M = {}

local OFFICIAL_BASE = "https://github.com/"
local DEFAULT_PROXY_BASE = "https://ghfast.top/https://github.com/"
local session_mode

local function normalized_base(base)
	base = base or DEFAULT_PROXY_BASE
	if not base:match("/$") then
		base = base .. "/"
	end
	return base
end

local function detect_mode()
	if vim.fn.executable("curl") ~= 1 or not vim.system then
		return "proxy"
	end

	local result = vim.system({
		"curl",
		"-I",
		"--max-time",
		"1.5",
		"https://github.com",
	}, { text = true }):wait()

	return result.code == 0 and "direct" or "proxy"
end

function M.mode(force_refresh)
	if session_mode and not force_refresh then
		return session_mode
	end

	local requested = (vim.env.GITHUB_PROXY_MODE or "proxy"):lower()
	if requested ~= "proxy" and requested ~= "direct" and requested ~= "auto" then
		requested = "proxy"
	end

	if requested == "auto" then
		session_mode = detect_mode()
	else
		session_mode = requested
	end

	return session_mode
end

function M.base(force_refresh)
	if M.mode(force_refresh) == "direct" then
		return OFFICIAL_BASE
	end
	return normalized_base(vim.env.GITHUB_PROXY_BASE)
end

function M.repo_url_format(force_refresh)
	return M.base(force_refresh) .. "%s.git"
end

function M.repo_url(repo, force_refresh)
	return M.repo_url_format(force_refresh):format(repo)
end

function M.release_download_template(force_refresh)
	return M.base(force_refresh) .. "%s/releases/download/%s/%s"
end

function M.describe(force_refresh)
	return string.format("[github] mode=%s base=%s", M.mode(force_refresh), M.base(force_refresh))
end

function M.apply_mason_settings(force_refresh)
	local ok, mason_settings = pcall(require, "mason.settings")
	if not ok then
		return M.mode(force_refresh)
	end

	mason_settings.set({
		github = {
			download_url_template = M.release_download_template(force_refresh),
		},
	})

	return M.mode(force_refresh)
end

return M
