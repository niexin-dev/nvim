return {
	name = "nx-terminal",
	dir = vim.fn.stdpath("config") .. "/lua/nx/nx-terminal",
	keys = {
		{
			"<leader>fw",
			function()
				require("nx-terminal").new()
			end,
			desc = "New terminal",
		},
		{
			"<leader>fa",
			function()
				require("nx-terminal").toggle()
			end,
			desc = "Toggle terminal",
		},
		{
			"<leader>m",
			function()
				require("nx-terminal").zoom_toggle()
			end,
			desc = "Zoom",
		},

		-- 终端模式：仅退出到 Normal
		{ "<leader>ee", [[<C-\><C-n>]], mode = "t", desc = "Terminal: exit to Normal" },

		-- 终端模式：退出到 Normal 并隐藏当前终端窗口
		{
			"<leader>ea",
			function()
				require("nx-terminal").escape_hide()
			end,
			mode = "t",
			desc = "Terminal: exit + hide",
		},
	},
	config = function()
		require("nx-terminal").setup()
	end,
}
