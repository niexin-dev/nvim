return {
	"kylechui/nvim-surround",
	version = "*", -- Use for stability; omit to use `main` branch for the latest features
	keys = {
		"ys",
		"cs",
		"ds",
		{ "S", mode = "x" },
	},
	config = function()
		require("nvim-surround").setup({
			-- Configuration here, or leave empty to use defaults
		})
	end,
}
