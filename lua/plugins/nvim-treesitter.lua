return {
	{
		"nvim-treesitter/nvim-treesitter",
		event = { "BufReadPost", "BufNewFile" },
		build = ":TSUpdate",
		opts = {
			-- 按需自动安装的 parser 白名单：打开对应 filetype 时，如本地缺失则自动安装
			ensure_installed = {
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
			},
		},
		config = function(_, opts)
			local ts = require("nvim-treesitter")
			require("nvim-treesitter.config").setup(opts)

			vim.treesitter.language.register("json", "jsonc")
			vim.treesitter.language.register("markdown", "markdown.mdx")

			-- 把白名单列表转成 set，FileType 回调里判断更直接。
			local auto_install_whitelist = {}
			for _, lang in ipairs(opts.ensure_installed or {}) do
				auto_install_whitelist[lang] = true
			end

			-- 同一会话里每种语言只尝试安装一次，避免连续打开多个 buffer 时重复触发。
			local install_attempted = {}
			-- 少数 filetype 和 parser 名不一致，这里做最小映射。
			local ft_to_lang = {
				jsonc = "json",
				["markdown.mdx"] = "markdown",
			}

			-- 用单独的 augroup 管理按 filetype 自动安装 parser 的 autocmd。
			local group = vim.api.nvim_create_augroup("nx_treesitter_install", { clear = true })
			vim.api.nvim_create_autocmd("FileType", {
				group = group,
				pattern = "*",
				callback = function(args)
					local ft = vim.bo[args.buf].filetype
					local lang = ft_to_lang[ft] or ft
					if not auto_install_whitelist[lang] or install_attempted[lang] then
						return
					end

					local installed = ts.get_installed()
					if vim.tbl_contains(installed, lang) then
						return
					end

					install_attempted[lang] = true
					local ok, installer = pcall(ts.install, { lang })
					if not ok or not installer then
						return
					end

					if type(installer.wait) == "function" then
						-- 安装完成后再为当前 buffer 启动 treesitter，避免还要手动重载文件。
						vim.schedule(function()
							local done = pcall(installer.wait, installer, 300000)
							if done then
								pcall(vim.treesitter.start, args.buf)
							end
						end)
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
