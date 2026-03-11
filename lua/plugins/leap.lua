return {
	url = "https://codeberg.org/andyg/leap.nvim",
	dependencies = { "tpope/vim-repeat" }, -- enable '.' repeat support
	-- lazy-load when user presses these keys (use <Plug> mappings provided by leap)
	keys = {
		{
			"<leader>w",
			"<Plug>(leap)",
			mode = { "n", "x", "o" },
			desc = "Leap: jump (forward)",
			noremap = true,
			silent = true,
		},

		{
			"<leader>W",
			"<Plug>(leap-from-window)",
			mode = "n",
			desc = "Leap: jump from window",
			noremap = true,
			silent = true,
		},
	},
	opts = {},
}
