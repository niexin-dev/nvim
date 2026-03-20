-- LSP 面包屑导航。
-- 1. 本身不直接显示 UI，主要给 lualine 等位置组件提供当前位置路径。
-- 2. 只在 LspAttach 后参与工作，避免无 LSP buffer 里多余初始化。
return {
	"SmiteshP/nvim-navic",
	event = "LspAttach",
	opts = {
		highlight = true,
		separator = " > ",
		depth_limit = 5,
	},
}
