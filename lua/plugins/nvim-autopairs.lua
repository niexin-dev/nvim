-- 自动补全括号/引号。
-- 1. 只在 InsertEnter 后介入，减少普通模式下的无关初始化。
-- 2. 借 treesitter 判断上下文，尽量避免在字符串或注释里错误补对。
return {
	"windwp/nvim-autopairs",
	event = "InsertEnter",
	opts = {
		check_ts = true, -- 使用 treesitter 检查语法
		ts_config = {
			lua = { "string" }, -- 在 lua 字符串中不自动配对
			javascript = { "template_string" },
			c = { "string", "comment" }, -- 在 C 字符串和注释中不自动配对
			cpp = { "string", "comment" }, -- 在 C++ 字符串和注释中不自动配对
		},
	},
}
