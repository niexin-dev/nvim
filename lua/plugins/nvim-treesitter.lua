return {
	{
		"nvim-treesitter/nvim-treesitter",
		event = { "BufReadPost", "BufNewFile" },
		build = ":TSUpdate",
		opts = {
			ensure_installed = {
				"bash",
				"c",
				"cpp",
				"json",
				"lua",
				"markdown",
				"yaml",
			},
		},
		config = function(_, opts)
			require("nvim-treesitter.configs").setup(opts)
			-- jsonc 复用 json parser，避免 unsupported language 警告
			vim.treesitter.language.register("json", "jsonc")
			-- mdx 复用 markdown parser
			vim.treesitter.language.register("markdown", "markdown.mdx")

			-- 新版 treesitter 需要显式启动高亮
			local group = vim.api.nvim_create_augroup("nx_treesitter_start", { clear = true })
			vim.api.nvim_create_autocmd("FileType", {
				group = group,
				callback = function(args)
					pcall(vim.treesitter.start, args.buf)
				end,
			})
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		event = { "BufReadPost", "BufNewFile" },
		opts = {
			move = { set_jumps = true },
		},
			config = function(_, opts)
				require("nvim-treesitter-textobjects").setup(opts)

				local move = require("nvim-treesitter-textobjects.move")
				local swap = require("nvim-treesitter-textobjects.swap")
				local map = vim.keymap.set

				map({ "n", "x", "o" }, "]f", function()
					move.goto_next_start("@function.outer", "textobjects")
				end, { desc = "TS Next Function Start" })
				map({ "n", "x", "o" }, "]c", function()
					move.goto_next_start("@class.outer", "textobjects")
				end, { desc = "TS Next Class Start" })
				map({ "n", "x", "o" }, "]a", function()
					move.goto_next_start("@parameter.inner", "textobjects")
				end, { desc = "TS Next Param" })
				map({ "n", "x", "o" }, "]F", function()
					move.goto_next_end("@function.outer", "textobjects")
				end, { desc = "TS Next Function End" })
				map({ "n", "x", "o" }, "]C", function()
					move.goto_next_end("@class.outer", "textobjects")
				end, { desc = "TS Next Class End" })
				map({ "n", "x", "o" }, "]A", function()
					move.goto_next_end("@parameter.inner", "textobjects")
				end, { desc = "TS Next Param End" })
				map({ "n", "x", "o" }, "[f", function()
					move.goto_previous_start("@function.outer", "textobjects")
				end, { desc = "TS Prev Function Start" })
				map({ "n", "x", "o" }, "[c", function()
					move.goto_previous_start("@class.outer", "textobjects")
				end, { desc = "TS Prev Class Start" })
				map({ "n", "x", "o" }, "[a", function()
					move.goto_previous_start("@parameter.inner", "textobjects")
				end, { desc = "TS Prev Param" })
				map({ "n", "x", "o" }, "[F", function()
					move.goto_previous_end("@function.outer", "textobjects")
				end, { desc = "TS Prev Function End" })
				map({ "n", "x", "o" }, "[C", function()
					move.goto_previous_end("@class.outer", "textobjects")
				end, { desc = "TS Prev Class End" })
				map({ "n", "x", "o" }, "[A", function()
					move.goto_previous_end("@parameter.inner", "textobjects")
				end, { desc = "TS Prev Param End" })
				map("n", "<leader>a", function()
					swap.swap_next("@parameter.inner")
				end, { desc = "TS Swap Next Param" })
				map("n", "<leader>A", function()
					swap.swap_previous("@parameter.inner")
				end, { desc = "TS Swap Prev Param" })
			end,
		},

	{
		"nvim-treesitter/nvim-treesitter-context",
		dependencies = { "nvim-treesitter/nvim-treesitter" }, -- 确保顺序正确
		-- 这里我给你改成文件读完后再加载，比 VeryLazy 更「跟着文件走」
		event = "BufReadPost",
		opts = {
			enable = true,
			multiwindow = false,
			max_lines = 0,
			min_window_height = 0,
			line_numbers = true,
			multiline_threshold = 20,
			trim_scope = "outer",
			mode = "cursor",
			separator = nil,
			zindex = 20,
			on_attach = nil,
		},
	},
}
