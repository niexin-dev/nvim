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
			require("nvim-treesitter.config").setup(opts)
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
			select = {
				lookahead = true,
				selection_modes = {
					["@parameter.outer"] = "v",
					["@function.outer"] = "V",
					["@class.outer"] = "V",
				},
				include_surrounding_whitespace = false,
			},
			move = { set_jumps = true },
		},
		config = function(_, opts)
			require("nvim-treesitter-textobjects").setup(opts)

			local move = require("nvim-treesitter-textobjects.move")
			local select = require("nvim-treesitter-textobjects.select")
			local swap = require("nvim-treesitter-textobjects.swap")
			local map = vim.keymap.set

			map({ "x", "o" }, "af", function()
				select.select_textobject("@function.outer", "textobjects")
			end, { desc = "TS Select Around Function" })
			map({ "x", "o" }, "if", function()
				select.select_textobject("@function.inner", "textobjects")
			end, { desc = "TS Select Inner Function" })
			map({ "x", "o" }, "ac", function()
				select.select_textobject("@class.outer", "textobjects")
			end, { desc = "TS Select Around Class" })
			map({ "x", "o" }, "ic", function()
				select.select_textobject("@class.inner", "textobjects")
			end, { desc = "TS Select Inner Class" })
			map({ "x", "o" }, "as", function()
				select.select_textobject("@local.scope", "locals")
			end, { desc = "TS Select Scope" })

			map({ "n", "x", "o" }, "<leader>jf", function()
				move.goto_next_start("@function.outer", "textobjects")
			end, { desc = "TS Next Function Start" })
			map({ "n", "x", "o" }, "<leader>jc", function()
				move.goto_next_start("@class.outer", "textobjects")
			end, { desc = "TS Next Class Start" })
			map({ "n", "x", "o" }, "<leader>ja", function()
				move.goto_next_start("@parameter.inner", "textobjects")
			end, { desc = "TS Next Param" })
			map({ "n", "x", "o" }, "<leader>kf", function()
				move.goto_previous_start("@function.outer", "textobjects")
			end, { desc = "TS Prev Function Start" })
			map({ "n", "x", "o" }, "<leader>kc", function()
				move.goto_previous_start("@class.outer", "textobjects")
			end, { desc = "TS Prev Class Start" })
			map({ "n", "x", "o" }, "<leader>ka", function()
				move.goto_previous_start("@parameter.inner", "textobjects")
			end, { desc = "TS Prev Param" })
			map("n", "<leader>xj", function()
				swap.swap_next("@parameter.inner")
			end, { desc = "TS Swap Next Param" })
			map("n", "<leader>xk", function()
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
