-- LSP 调用树面板。
-- 1. litee.nvim 提供承载面板，litee-calltree 只负责 incoming/outgoing calls。
-- 2. 这里默认 popout，避免长期占据主编辑区域。
return {
	{
		"niexin-dev/litee.nvim",
		event = "VeryLazy",
		opts = {
			notify = { enabled = false },
			panel = {
				orientation = "bottom",
				panel_size = 10,
			},
		},
		config = function(_, opts)
			require("litee.lib").setup(opts)
		end,
	},

	{
		"niexin-dev/litee-calltree.nvim",
		dependencies = "niexin-dev/litee.nvim",
		event = "VeryLazy",
		opts = {
			-- panel 在bottom显示窗口
			-- popout 弹出浮动窗口
			on_open = "popout",
			map_resize_keys = false,
			keymaps = {
				toggle = "<tab>",
			},
		},
		keys = {
			-- Incoming / Outgoing 调用树
			{
				"<leader>li",
				function()
					vim.lsp.buf.incoming_calls()
				end,
				desc = "LSP: Incoming Calls (Calltree)",
			},
			{
				"<leader>lo",
				function()
					vim.lsp.buf.outgoing_calls()
				end,
				desc = "LSP: Outgoing Calls (Calltree)",
			},
			{ "<leader>lp", "<cmd>LTPopOutCalltree<CR>", desc = "LSP: Calltree PopOut" },
		},
		config = function(_, opts)
			require("litee.calltree").setup(opts)
		end,
	},
}
