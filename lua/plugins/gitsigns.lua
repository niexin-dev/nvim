-- Git 侧边标记与 hunk 操作入口。
-- 1. 结合 dashboard-first 工作流延后到 VeryLazy，再由 gitsigns 自己回头 attach buffer。
-- 2. 默认保留常用的 sign/numhl，关闭更吵的 linehl、word_diff、blame，减少视觉和更新开销。
-- 3. 绝大多数键位都放在 on_attach 里，只对真正处于 Git 仓库的 buffer 生效。
return {
	"lewis6991/gitsigns.nvim",
	-- 配合 dashboard 首屏，先让 UI 稳定下来，再初始化 Git 状态。
	event = "VeryLazy",
	cmd = { "Gitsigns" },

	opts = {
		signs = {
			add = { text = "┃" },
			change = { text = "┃" },
			delete = { text = "_" },
			topdelete = { text = "‾" },
			changedelete = { text = "~" },
			untracked = { text = "┆" },
		},
		signs_staged = {
			add = { text = "┃" },
			change = { text = "┃" },
			delete = { text = "_" },
			topdelete = { text = "‾" },
			changedelete = { text = "~" },
			untracked = { text = "┆" },
		},
		signs_staged_enable = false,
		signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
		numhl = true, -- Toggle with `:Gitsigns toggle_numhl`
		linehl = false, -- Toggle with `:Gitsigns toggle_linehl`
		word_diff = false, -- Toggle with `:Gitsigns toggle_word_diff`
		watch_gitdir = {
			interval = 1000,
			follow_files = true,
		},
		auto_attach = true,
		attach_to_untracked = false,
		current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
		current_line_blame_opts = {
			virt_text = true,
			virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
			delay = 1000,
			ignore_whitespace = false,
			virt_text_priority = 100,
			use_focus = true,
		},
		current_line_blame_formatter = "<author>, <author_time:%R> - <summary>",
		sign_priority = 6,
		update_debounce = 100,
		status_formatter = nil, -- Use default
		max_file_length = 20000, -- Disable if file is longer than this (in lines)
		preview_config = {
			-- Options passed to nvim_open_win
			border = "single",
			style = "minimal",
			relative = "cursor",
			row = 0,
			col = 1,
		},
		on_attach = function(bufnr)
			local gs = package.loaded.gitsigns or require("gitsigns")
			-- 这些映射只有在当前 buffer 真正 attach 到 gitsigns 后才有意义。
			local maps = {
				{ mode = "n", lhs = "<leader>gj", rhs = gs.next_hunk, desc = "Next hunk" },
				{ mode = "n", lhs = "<leader>gk", rhs = gs.prev_hunk, desc = "Previous hunk" },
				{ mode = "n", lhs = "<leader>gs", rhs = gs.stage_hunk, desc = "Stage hunk" },
				{
					mode = "v",
					lhs = "<leader>gs",
					rhs = function()
						gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
					end,
					desc = "Stage selected hunk",
				},
				{ mode = "n", lhs = "<leader>gr", rhs = gs.reset_hunk, desc = "Reset hunk" },
				{
					mode = "v",
					lhs = "<leader>gr",
					rhs = function()
						gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
					end,
					desc = "Reset selected hunk",
				},
				{ mode = "n", lhs = "<leader>gS", rhs = gs.stage_buffer, desc = "Stage buffer" },
				{ mode = "n", lhs = "<leader>gu", rhs = gs.undo_stage_hunk, desc = "Undo stage hunk" },
				{ mode = "n", lhs = "<leader>gR", rhs = gs.reset_buffer, desc = "Reset buffer" },
				{ mode = "n", lhs = "<leader>gp", rhs = gs.preview_hunk, desc = "Preview hunk" },
				{
					mode = "n",
					lhs = "<leader>gl",
					rhs = function()
						gs.blame_line({ full = true })
					end,
					desc = "Blame line (full)",
				},
				{ mode = "n", lhs = "<leader>gB", rhs = gs.toggle_current_line_blame, desc = "Toggle current line blame" },
				{ mode = "n", lhs = "<leader>g=", rhs = gs.diffthis, desc = "Diff against index" },
				{
					mode = "n",
					lhs = "<leader>g-",
					rhs = function()
						gs.diffthis("~")
					end,
					desc = "Diff against last commit",
				},
				{ mode = "n", lhs = "<leader>gX", rhs = gs.toggle_deleted, desc = "Toggle deleted hunks" },
				{ mode = { "o", "x" }, lhs = "ih", rhs = gs.select_hunk, desc = "Select hunk" },
			}

			for _, map in ipairs(maps) do
				vim.keymap.set(map.mode, map.lhs, map.rhs, {
					buffer = bufnr,
					silent = true,
					noremap = true,
					desc = map.desc,
				})
			end
		end,
	},
}
