-- Markdown 预览增强。
-- 1. 只给 markdown 和 codecompanion 会话缓冲区使用，避免干扰普通文本。
-- 2. 和 codecompanion 配合时，可以把 AI 生成的 markdown 结果直接渲染出来。
return {
	"OXY2DEV/markview.nvim",
	ft = { "markdown", "codecompanion" },
	opts = {
		preview = {
			filetypes = { "markdown", "codecompanion" },
			ignore_buftypes = {},
		},
		experimental = { check_rtp_message = false },
	},
}
