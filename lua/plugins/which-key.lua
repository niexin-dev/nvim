-- 键位提示面板。
-- 1. 只在 VeryLazy 后提供查询能力，不参与启动主路径。
-- 2. 当前只保留最基础的 buffer-local 查看入口，避免 which-key 抢过多控制权。
return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		-- your configuration comes here
		-- or leave it empty to use the default settings
		-- refer to the configuration section below
	},
	keys = {
		{
			"<leader>?",
			function()
				require("which-key").show({ global = false })
			end,
			desc = "Buffer Local Keymaps (which-key)",
		},
	},
}
