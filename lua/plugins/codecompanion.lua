-- AI 工作流入口。
-- 1. 主要用 codex 作为默认适配器，其他厂商模型保留为补充出口。
-- 2. prompt_library 存的是高频中文模板，目的是把“重复描述规则”固化下来。
-- 3. commit message 模板直接读取 staged diff，因此依赖当前 cwd 已经落在正确仓库。
local adapters = require("config.codecompanion.adapters")
local keys = require("config.codecompanion.keys")
local prompt_library = require("config.codecompanion.prompts")

return {
	"olimorris/codecompanion.nvim",
	cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions", "CodeCompanionAsk" },
	config = true,
	dependencies = {
		"nvim-lua/plenary.nvim", -- 提供底层工具函数
		"nvim-treesitter/nvim-treesitter", -- 供上下文提取和代码理解使用
		"ravitemer/codecompanion-history.nvim", -- 保留聊天历史
	},

	version = "*",
	opts = {
		opts = {
			language = "Chinese",
			-- log_level = "TRACE",  -- TRACE|DEBUG|ERROR|INFO
		},
		strategies = {
			-- 三种交互都统一走 codex，减少“聊天和编辑不是同一个模型”的上下文割裂。
			chat = {
				adapter = "codex",
			},
			inline = {
				adapter = "codex",
			},
			cmd = {
				adapter = "codex",
			},
		},
		adapters = adapters,
		-- 预定义提示库。这里优先沉淀“经常要说、但每次都不想重说”的约束。
		prompt_library = prompt_library,
		extensions = {
			history = {
				enabled = true,
				opts = {
					-- Keymap to open history from chat buffer (default: gh)
					keymap = "gh",
					-- Keymap to save the current chat manually (when auto_save is disabled)
					save_chat_keymap = "sc",
					-- Save all chats by default (disable to save only manually using 'sc')
					auto_save = true,
					-- Number of days after which chats are automatically deleted (0 to disable)
					expiration_days = 0,
					-- Picker interface (auto resolved to a valid picker)
					picker = "fzf-lua", --- ("telescope", "snacks", "fzf-lua", or "default")
					---Automatically generate titles for new chats
					auto_generate_title = false,
					title_generation_opts = {
						---Adapter for generating titles (defaults to current chat adapter)
						adapter = "deepseek",
						---Model for generating titles (defaults to current chat model)
						model = "deepseek-chat",
						---Number of user prompts after which to refresh the title (0 to disable)
						refresh_every_n_prompts = 0, -- e.g., 3 to refresh after every 3rd user prompt
						---Maximum number of times to refresh the title (default: 3)
						max_refreshes = 3,
					},
					---On exiting and entering neovim, loads the last chat on opening chat
					continue_last_chat = false,
					---When chat is cleared with `gx` delete the chat from history
					delete_on_clearing_chat = false,
					---Directory path to save the chats
					dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
					---Enable detailed logging for history extension
					enable_logging = false,
				},
			},
		},
	},
	keys = keys,
}
