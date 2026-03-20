-- 行内诊断展示。
-- 1. 在 LspAttach 后启用，用更紧凑的 inline UI 替代原生 virtual_text。
-- 2. 这里只负责展示层，不改变诊断来源和跳转逻辑。
return {
	"rachartier/tiny-inline-diagnostic.nvim",
	event = "LspAttach",
	config = function()
		require("tiny-inline-diagnostic").setup()
		vim.diagnostic.config({ virtual_text = false }) -- Only if needed in your configuration, if you already have native LSP diagnostics
	end,
}
