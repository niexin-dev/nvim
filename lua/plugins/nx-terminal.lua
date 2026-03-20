-- 本地终端管理器。
-- 1. 走 lazy keys 保证首次按键就能执行，所以插件内部映射要关闭，避免重复绑定。
-- 2. 终端新建、切换、放大和退出动作都集中在这里，减少散落映射。
return {
	name = "nx-terminal",
	dir = vim.fn.stdpath("config") .. "/lua/nx/nx-terminal",
	keys = {
		{
			"<leader>tn",
			function()
				require("nx-terminal").new()
			end,
			mode = "n",
			desc = "New terminal",
		},
		{
			"<leader>tt",
			function()
				require("nx-terminal").toggle()
			end,
			mode = "n",
			desc = "Toggle terminal",
		},
		{
			"<leader>tz",
			function()
				require("nx-terminal").zoom_toggle()
			end,
			mode = "n",
			desc = "Toggle maximize current buffer (via tab)",
		},
		{
			"<leader>te",
			function()
				require("nx-terminal").escape()
			end,
			mode = "t",
			desc = "Terminal: exit to Normal",
		},
		{
			"<leader>th",
			function()
				require("nx-terminal").escape_hide()
			end,
			mode = "t",
			desc = "Terminal: exit + hide",
		},
	},
	config = function()
		require("nx-terminal").setup({
			-- Mappings are provided by lazy keys above to ensure first-hit execution.
			mappings = false,
		})
	end,
}
