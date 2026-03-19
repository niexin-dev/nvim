-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- 尽早启用 Lua 模块缓存，后续 require 才能受益
if vim.loader and vim.loader.enable then
	vim.loader.enable()
end

if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
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
	rocks = { enabled = false },
	-- Configure any other settings here. See the documentation for more details.
	-- colorscheme that will be used when installing plugins.
	install = { colorscheme = { "tokyonight" } },
	-- startup-speed profile: disable periodic update checks
	checker = { enabled = false },
})
