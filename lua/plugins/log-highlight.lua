-- 日志高亮。
-- 1. 只在 log/text 相关文件里启用，避免普通代码文件也加载这类专项插件。
-- 2. 主要用于快速扫日志级别、时间戳和常见关键字。
return {
	"fei6409/log-highlight.nvim",
	ft = { "log", "text" },
	opts = {
		extension = { "log", "txt" },
	},
	config = function(_, opts)
		require("log-highlight").setup(opts)
	end,
}
