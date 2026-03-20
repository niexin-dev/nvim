-- 注释模板生成。
-- 1. 依赖 treesitter 识别当前位置语法结构，所以更适合函数/类等结构化代码。
-- 2. 和 codecompanion 的“补详细中文注释”不同，这里主要解决注释骨架生成。
return {
	"danymat/neogen",
	dependencies = "nvim-treesitter/nvim-treesitter",
	config = true,
	cmd = "Neogen",
	keys = {
		{
			"<leader>ng", -- 生成注释
			function()
				require("neogen").generate({})
			end,
			desc = "Generate Annotation (Neogen)", -- 快捷键描述
		},
	},
}
