-- 包裹编辑。
-- 1. 主要使用场景是普通模式下的 ys/cs/ds，所以直接按这些键懒加载。
-- 2. 这样可以避免首击 surround 时插件还没起来的问题。
return {
	"kylechui/nvim-surround",
	version = "*", -- Use for stability; omit to use `main` branch for the latest features
	keys = {
		"ys",
		"cs",
		"ds",
		{ "S", mode = "x" },
	},
	config = function()
		require("nvim-surround").setup({
			-- Configuration here, or leave empty to use defaults
		})
	end,
}
