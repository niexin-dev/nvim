-- 快速跳转。
-- 1. 用 <leader>w / <leader>W 触发，避免覆盖原生 s / S 一类高频键。
-- 2. 依赖 vim-repeat，让 leap 的跳转也能吃到 . 重复。
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
