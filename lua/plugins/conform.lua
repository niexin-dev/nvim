-- 统一格式化入口。
-- 1. 显式按文件类型挑 formatter，避免把“能不能格式化”分散在多个插件里。
-- 2. format_on_save 只对少数语言开启，保留可控性，避免所有文件都在写入时被改动。
return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>fm",
			function()
				require("conform").format({ async = true, lsp_format = "fallback" })
			end,
			mode = { "n" },
			desc = "Format buffer",
		},
		{
			"<leader>fm",
			function()
				require("conform").format({ async = true, lsp_format = "fallback" })
				vim.schedule(function()
					vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", false, false, true), "x", false)
				end)
			end,
			mode = { "v" },
			desc = "Format selection",
		},
	},
	-- 为 Lua 语言服务器提供类型标注提示
	---@module "conform"
	---@type conform.setupOpts
	opts = {
		-- 设置日志等级；使用 `:ConformInfo` 可以查看日志文件路径
		-- log_level = vim.log.levels.DEBUG,
		-- 针对不同文件类型指定使用的格式化器
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "isort", "black" },
			javascript = { "prettierd" },
			javascriptreact = { "prettierd" },
			typescript = { "prettierd" },
			typescriptreact = { "prettierd" },
			c = { "clang_format" },
			cpp = { "clang_format" },
			markdown = { "prettierd" },
			["markdown.mdx"] = { "prettierd" },
			json = { "prettierd" },
			yaml = { "prettierd" },
			html = { "prettierd" },
			css = { "prettierd" },
			scss = { "prettierd" },
			toml = { "taplo" },
			-- Conform 的 formatter 名称是 "bake"，其可执行文件通常是 mason 安装的 "mbake"
			make = { "bake" },
		},
		-- 默认的格式化设置
		default_format_opts = {
			lsp_format = "fallback",
		},
		format_on_save = function(bufnr)
			-- 这里只给“通常希望无脑保存即格式化”的语言开白名单。
			local ft = vim.bo[bufnr].filetype
			local enabled = {
				javascript = true,
				javascriptreact = true,
				typescript = true,
				typescriptreact = true,
				json = true,
				python = true,
			}

			if enabled[ft] then
				return { timeout_ms = 500, lsp_format = "fallback" }
			end
		end,
		-- 在此自定义各个格式化器的额外行为
		formatters = {
			shfmt = {
				prepend_args = { "-i", "2" },
			},
			clang_format = {
				command = "clang-format",
				-- 固定读取配置目录里的自定义样式文件，避免依赖各项目自己带 .clang-format。
				prepend_args = { "--style=file:" .. vim.fs.joinpath(vim.fn.stdpath("config"), "nx-clang-format") },
				range_args = function(self, ctx)
					return { "--lines", string.format("%d:%d", ctx.range.start[1], ctx.range["end"][1]) }
				end,
				stdin = true,
			},
		},
	},
	init = function()
		-- 在这里设置 formatexpr，启用 Conform 提供的格式化表达式
		vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
	end,
}
