-- 图标公共依赖。
-- 1. 只提供图标表，不单独承担交互功能。
-- 2. 保持 lazy，让真正需要图标的插件自行拉起它。
return {
	"nvim-tree/nvim-web-devicons",
	lazy = true,
	opts = {},
}
