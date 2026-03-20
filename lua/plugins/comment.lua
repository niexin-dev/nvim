-- 基础注释操作。
-- 1. 只保留 gc/gcc/gC 这一层能力，走纯按键懒加载即可。
-- 2. 没有放额外钩子，目的是保持行为尽量接近默认 Comment.nvim。
return -- add this to your lua/plugins.lua, lua/plugins/init.lua,  or the file you keep your other plugins:
{
	"numToStr/Comment.nvim",
	keys = { "gc", "gcc", "gC" },
	opts = {
		-- add any options here
	},
}
