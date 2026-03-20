-- 经典 Git 命令入口。
-- 1. 这里只保留最顺手的 :Git 和 blame 入口，复杂 Git 视图仍交给 fugitive 自己处理。
-- 2. 和 gitsigns 是互补关系：gitsigns 看工作区增量，fugitive 做命令级操作。
return {
	"tpope/vim-fugitive",

	keys = {
		{ "<leader>gg", "<cmd>Git<cr>", desc = "vim-fugitive" },
		{ "<leader>gb", "<cmd>Git blame<cr>", desc = "Git blame" },
	},
}
