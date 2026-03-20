-- 轻量书签。
-- 1. 纯命令触发，避免为了偶尔用到的书签功能进入普通文件打开热路径。
-- 2. 这里的高亮和标记样式是为了让书签在长文件里足够醒目。
return {
	"MattesGroeger/vim-bookmarks",
	name = "bookmarks",
	cmd = {
		"BookmarkToggle",
		"BookmarkAnnotate",
		"BookmarkShowAll",
		"BookmarkClearAll",
		"BookmarkNext",
		"BookmarkPrev",
	},
	init = function()
		vim.g.bookmark_sign = "⚑"
		vim.g.bookmark_highlight_group = "BookmarkLine"
		vim.g.bookmark_highlight_lines = 1
		vim.g.bookmark_auto_save = 0
	end,
	config = function()
		vim.api.nvim_set_hl(0, "BookmarkLine", {
			-- 对于真彩色终端 (termguicolors 开启时):
			-- 使用十六进制颜色值设置背景和前景
			bg = "#0087ff", -- 蓝色背景
			fg = "#000135", -- 黑色前景
			-- 对于 256 色终端 (termguicolors 关闭时):
			-- 使用预定义颜色名称设置背景和前景
			ctermbg = "blue", -- 蓝色背景
			ctermfg = "black", -- 黑色前景
			-- 你还可以添加其他属性，例如 'bold = true'
			-- bold = true,
		})
	end,
}
