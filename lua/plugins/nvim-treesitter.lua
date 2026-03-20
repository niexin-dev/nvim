-- Treesitter 基础设施。
-- 1. 这是语法高亮、文本对象、上下文窗口等能力的底座，所以核心插件常驻加载。
-- 2. parser 安装被延后到 VeryLazy 之后，避免空启动时就做安装检查。
-- 3. 真正启动 parser 前还会过一层大文件 / 特殊 buffer 保护，防止重文件拖慢体验。
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

local max_filesize = 1024 * 1024
local max_lines = 20000

local select_specs = {
	{ modes = { "x", "o" }, lhs = "af", query = "@function.outer", group = "textobjects", desc = "TS Select Around Function" },
	{ modes = { "x", "o" }, lhs = "if", query = "@function.inner", group = "textobjects", desc = "TS Select Inner Function" },
	{ modes = { "x", "o" }, lhs = "ac", query = "@class.outer", group = "textobjects", desc = "TS Select Around Class" },
	{ modes = { "x", "o" }, lhs = "ic", query = "@class.inner", group = "textobjects", desc = "TS Select Inner Class" },
	{ modes = { "x", "o" }, lhs = "as", query = "@local.scope", group = "locals", desc = "TS Select Scope" },
}

local move_specs = {
	{ modes = { "n", "x", "o" }, lhs = "<leader>jf", query = "@function.outer", desc = "TS Next Function Start", fn_name = "goto_next_start" },
	{ modes = { "n", "x", "o" }, lhs = "<leader>jc", query = "@class.outer", desc = "TS Next Class Start", fn_name = "goto_next_start" },
	{ modes = { "n", "x", "o" }, lhs = "<leader>ja", query = "@parameter.inner", desc = "TS Next Param", fn_name = "goto_next_start" },
	{ modes = { "n", "x", "o" }, lhs = "<leader>kf", query = "@function.outer", desc = "TS Prev Function Start", fn_name = "goto_previous_start" },
	{ modes = { "n", "x", "o" }, lhs = "<leader>kc", query = "@class.outer", desc = "TS Prev Class Start", fn_name = "goto_previous_start" },
	{ modes = { "n", "x", "o" }, lhs = "<leader>ka", query = "@parameter.inner", desc = "TS Prev Param", fn_name = "goto_previous_start" },
}

local swap_specs = {
	{ lhs = "<leader>xj", query = "@parameter.inner", desc = "TS Swap Next Param", fn_name = "swap_next" },
	{ lhs = "<leader>xk", query = "@parameter.inner", desc = "TS Swap Prev Param", fn_name = "swap_previous" },
}

local function should_start_parser(bufnr, uv)
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

local function setup_textobject_keymaps()
	local move = require("nvim-treesitter-textobjects.move")
	local select = require("nvim-treesitter-textobjects.select")
	local swap = require("nvim-treesitter-textobjects.swap")

	for _, spec in ipairs(select_specs) do
		vim.keymap.set(spec.modes, spec.lhs, function()
			select.select_textobject(spec.query, spec.group)
		end, { desc = spec.desc })
	end

	for _, spec in ipairs(move_specs) do
		vim.keymap.set(spec.modes, spec.lhs, function()
			move[spec.fn_name](spec.query, "textobjects")
		end, { desc = spec.desc })
	end

	for _, spec in ipairs(swap_specs) do
		vim.keymap.set("n", spec.lhs, function()
			swap[spec.fn_name](spec.query)
		end, { desc = spec.desc })
	end
end

return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			local ts = require("nvim-treesitter")
			local uv = vim.uv or vim.loop

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

			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("nx_treesitter_start", { clear = true }),
				callback = function(args)
					if should_start_parser(args.buf, uv) then
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

			setup_textobject_keymaps()
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
