-- filetype 识别与按语言缩进策略。
-- 1. 把扩展名映射和缩进规则集中管理，避免散落在 options 或插件配置里。
-- 2. 这里只处理“编辑器基础认知”，不处理插件级语言能力。
vim.filetype.add({
	extension = {
		h = "c",
		mdx = "markdown.mdx",
	},
})

-- 将 .h 文件的语法高亮设置为 C。
vim.g.c_syntax_for_h = 1

local indent_group = vim.api.nvim_create_augroup("UserFiletypeIndent", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
	group = indent_group,
	pattern = {
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
		"json",
		"yaml",
		"html",
		"css",
		"scss",
		"markdown",
		"markdown.mdx",
	},
	callback = function()
		-- 前端 / 标记类文件统一用 2 空格，避免跟 C/Lua/Python 的 4 空格习惯混在一起。
		vim.opt_local.tabstop = 2
		vim.opt_local.shiftwidth = 2
		vim.opt_local.softtabstop = 2
	end,
})
