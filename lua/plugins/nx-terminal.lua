return {
	name = "nx-terminal",
	dir = vim.fn.stdpath("config") .. "/lua/nx/nx-terminal",
	keys = {
		{
			"<leader>fw",
			function()
				require("nx-terminal").new()
			end,
			mode = "n",
			desc = "New terminal",
		},
		{
			"<leader>fa",
			function()
				require("nx-terminal").toggle()
			end,
			mode = "n",
			desc = "Toggle terminal",
		},
		{
			"<leader>m",
			function()
				require("nx-terminal").zoom_toggle()
			end,
			mode = "n",
			desc = "Toggle maximize current buffer (via tab)",
		},
		{
			"<leader>ee",
			function()
				require("nx-terminal").escape()
			end,
			mode = "t",
			desc = "Terminal: exit to Normal",
		},
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
		require("nx-terminal").setup({
			-- Mappings are provided by lazy keys above to ensure first-hit execution.
			mappings = false,
		})
	end,
}
