-- lazy.nvim 启动入口。
-- 1. 先启用 vim.loader，再 bootstrap lazy.nvim，本质上是整套插件系统的装载器。
-- 2. 这里只负责“把插件规格读进来”，具体行为都在 lua/plugins/*.lua 里定义。
local github = require("config.github")

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- 尽早启用 Lua 模块缓存，后续 require 才能受益
if vim.loader and vim.loader.enable then
	vim.loader.enable()
end

if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = github.repo_url("folke/lazy.nvim")
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		local msg = table.concat({
			"Failed to clone lazy.nvim:",
			lazyrepo,
			out,
		}, "\n")
		vim.api.nvim_echo({
			{ msg, "ErrorMsg" },
		}, true, {})
		error(msg)
	end
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
require("lazy").setup({
	spec = {
		-- import your plugins
		{ import = "plugins" },
	},
	git = {
		-- 统一复用 GitHub 路由策略，让插件拉取和 bootstrap 走同一条链路。
		url_format = github.repo_url_format(),
	},
	rocks = { enabled = false },
	-- Configure any other settings here. See the documentation for more details.
	-- colorscheme that will be used when installing plugins.
	install = { colorscheme = { "tokyonight" } },
	-- startup-speed profile: disable periodic update checks
	checker = { enabled = false },
})
