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
