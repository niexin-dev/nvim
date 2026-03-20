-- Treesitter 基础设施。
-- 1. 这是语法高亮、文本对象、上下文窗口等能力的底座，所以核心插件常驻加载。
-- 2. parser 安装被延后到 VeryLazy 之后，避免空启动时就做安装检查。
-- 3. 真正启动 parser 前还会过一层大文件 / 特殊 buffer 保护，防止重文件拖慢体验。
return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			local ts = require("nvim-treesitter")
			local uv = vim.uv or vim.loop

			local parsers = {
				"bash",
				"c",
				"cpp",
				"css",
				"html",
				"javascript",
				"json",
				"lua",
				"markdown",
				"python",
				"scss",
				"tsx",
				"typescript",
				"yaml",
			}

			ts.setup({
				install_dir = vim.fn.stdpath("data") .. "/site",
			})

			vim.api.nvim_create_autocmd("User", {
				pattern = "VeryLazy",
				once = true,
				callback = function()
					vim.schedule(function()
						-- 缺 parser 时尽量自动补齐，但不把这件事放到首屏热路径里。
						pcall(ts.install, parsers)
					end)
				end,
			})

			vim.treesitter.language.register("json", "jsonc")
			vim.treesitter.language.register("markdown", "markdown.mdx")

			local max_filesize = 1024 * 1024
			local max_lines = 20000

			local function should_start(bufnr)
				if not vim.api.nvim_buf_is_valid(bufnr) then
					return false
				end

				if vim.bo[bufnr].buftype ~= "" or vim.bo[bufnr].filetype == "" then
					return false
				end

				if vim.api.nvim_buf_line_count(bufnr) > max_lines then
					return false
				end

				local name = vim.api.nvim_buf_get_name(bufnr)
				if name == "" then
					return true
				end

				local stat = uv.fs_stat(name)
				return not (stat and stat.size and stat.size > max_filesize)
			end

			local group = vim.api.nvim_create_augroup("nx_treesitter_start", { clear = true })
			vim.api.nvim_create_autocmd("FileType", {
				group = group,
				callback = function(args)
					if should_start(args.buf) then
						-- start 失败时静默兜底，避免单个 parser 异常打断编辑流。
						pcall(vim.treesitter.start, args.buf)
					end
				end,
			})
		end,
	},

	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			-- 文本对象相关映射集中放这里，便于按“选择 / 跳转 / 交换”三个维度理解。
			require("nvim-treesitter-textobjects").setup({
				select = {
					lookahead = true,
					selection_modes = {
						["@parameter.outer"] = "v",
						["@function.outer"] = "V",
						["@class.outer"] = "V",
					},
					include_surrounding_whitespace = false,
				},
				move = {
					set_jumps = true,
				},
			})

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
		-- 这是附加 UI，不需要参与最早的启动阶段。
		dependencies = { "nvim-treesitter/nvim-treesitter" },
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
