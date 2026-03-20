-- Codeium / Windsurf 补全入口。
-- 1. 只有检测到本地 language server 已经存在时才自动启用，避免首次启动时偷偷下载。
-- 2. 只开补全，不开聊天，也不接 nvim-cmp source，减少和 blink/codex 的职责重叠。
return {
	"Exafunction/windsurf.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	event = "VeryLazy",
	config = function()
		local function has_local_language_server()
			-- 先借 codeium 自己的配置/更新模块判断本地二进制是否就绪。
			local ok_cfg, cfg = pcall(require, "codeium.config")
			if not ok_cfg then
				return false
			end

			cfg.setup({
				enable_chat = false,
				enable_cmp_source = false,
			})

			local ok_update, update = pcall(require, "codeium.update")
			if not ok_update then
				return false
			end

			local ok_info, info = pcall(update.get_bin_info)
			if not ok_info or not info or not info.bin then
				return false
			end

			local uv = vim.uv or vim.loop
			return uv.fs_stat(info.bin) ~= nil
		end

		local function setup_codeium()
			require("codeium").setup({
				enable_chat = false, -- 禁用聊天
				enable_cmp_source = false, -- 不走 nvim-cmp source，避免 require("cmp")
			})
		end

		if not has_local_language_server() then
			if vim.fn.exists(":CodeiumBootstrap") == 0 then
				vim.api.nvim_create_user_command("CodeiumBootstrap", function()
					setup_codeium()
				end, { desc = "Initialize Codeium (may download language server)" })
			end
			vim.notify(
				"[codeium] 未检测到本地 language server，已跳过自动初始化。需要时执行 :CodeiumBootstrap",
				vim.log.levels.WARN
			)
			return
		end

		setup_codeium()
	end,
}
