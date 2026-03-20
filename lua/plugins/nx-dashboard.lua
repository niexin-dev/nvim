-- 本地 dashboard 的 lazy 包装层。
-- 1. 真正逻辑都在 lua/nx/nx-dashboard 里，这里只负责把它接进 lazy.nvim。
-- 2. 用 UIEnter/cmd/key 触发，既保留启动面板体验，又不让 headless/直接脚本调用受影响。
return {
	name = "nx-dashboard",
	dir = vim.fn.stdpath("config") .. "/lua/nx/nx-dashboard",
	event = "UIEnter",
	cmd = { "NxDashboard", "NxDashboardStats", "NxDashboardDebugToggle" },
	keys = {
		{ "<leader>fd", "<cmd>NxDashboard<cr>", desc = "Open startup dashboard" },
	},
	config = function()
		require("nx-dashboard").setup({
			-- 这里可覆盖你的配置
			-- use_icons = true,
			-- auto_open_on_uienter = true,
			map_open = "",
			-- cmd_open = "Dashboard", -- 想改成 NxDashboard 也可以
		})
	end,
}
