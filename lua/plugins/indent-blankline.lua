-- 缩进参考线。
-- 1. 这是纯视觉辅助，放在真实文件打开后再加载即可。
-- 2. 当前保持默认配置，说明你的主要诉求是“看得到层级”，不是深度定制样式。
return {
	"lukas-reineke/indent-blankline.nvim",
	main = "ibl",
	event = { "BufReadPost", "BufNewFile" },
	---@module "ibl"
	---@type ibl.config
	opts = {},
}
