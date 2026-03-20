-- 主主题。
-- 1. 主题需要最早生效，所以保持 eager load 和较高 priority。
-- 2. 开 cache 是为了减少重复解析主题定义的开销。
return {
	"folke/tokyonight.nvim",
	lazy = false,
	priority = 1000,
	opts = {
		style = "night",
		cache = true,
	},
	config = function(_, opts)
		local tokyonight = require("tokyonight")
		tokyonight.setup(opts)
		tokyonight.load({ style = opts.style })
	end,
}
