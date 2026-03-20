-- CodeCompanion 适配器集合。
-- 主路径默认走 codex，其余 HTTP / ACP 适配器保留为补充出口。
return {
	http = {
		deepseek = function()
			return require("codecompanion.adapters").extend("deepseek", {
				env = {
					api_key = "cmd:echo $DEEPSEEK_API_KEY",
				},
				schema = {
					model = {
						default = "deepseek-chat",
					},
				},
			})
		end,
		gemini = function()
			return require("codecompanion.adapters").extend("gemini", {
				env = {
					api_key = "cmd:echo $GEMINI_API_KEY",
				},
				schema = {
					model = {
						default = "gemini-2.5-flash",
					},
				},
			})
		end,
		openai = function()
			return require("codecompanion.adapters").extend("openai", {
				env = {
					api_key = "cmd:echo $OPENAI_API_KEY",
				},
				schema = {
					model = {
						default = "gpt-4o",
					},
				},
			})
		end,
		ollama = function()
			return require("codecompanion.adapters").extend("ollama", {
				env = {
					url = vim.env.OLLAMA_HOST or "http://127.0.0.1:11434",
				},
				schema = {
					model = {
						default = "qwen3-coder:30b",
					},
					num_ctx = {
						default = 32768,
					},
				},
			})
		end,
	},
	acp = {
		codex = function()
			local command = { "codex-acp" }
			if vim.fn.executable("codex-acp") ~= 1 then
				command = { "npx", "@zed-industries/codex-acp" }
			end

			return require("codecompanion.adapters").extend("codex", {
				commands = {
					default = command,
				},
				defaults = {
					auth_method = "chatgpt", -- "openai-api-key"|"codex-api-key"|"chatgpt"
					model = "gpt-5.4-mini",
					mode = "medium",
					timeout = 20000,
				},
			})
		end,
		gemini_cli = function()
			return require("codecompanion.adapters").extend("gemini_cli", {
				defaults = {
					auth_method = "oauth-personal",
				},
			})
		end,
	},
}
