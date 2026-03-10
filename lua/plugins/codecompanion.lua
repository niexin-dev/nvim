-- 返回一个Lua表，描述插件配置（符合lazy.nvim规范）
return {
	-- 插件GitHub仓库地址
	"olimorris/codecompanion.nvim",
	-- 自动加载默认配置
	cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions", "CodeCompanionAsk" },
	config = true,
	-- 声明依赖的其他插件
	dependencies = {
		"nvim-lua/plenary.nvim", -- 提供Lua工具函数
		"nvim-treesitter/nvim-treesitter", -- 语法分析
		"ravitemer/codecompanion-history.nvim", -- 历史记录
	},

	version = "*",
	-- 自定义配置选项
	opts = {
		-- 全局选项
		opts = {
			language = "Chinese", -- 设置默认语言为中文
			-- log_level = "TRACE",  -- TRACE|DEBUG|ERROR|INFO
		},
		-- 定义不同策略使用的适配器
		strategies = {
			chat = { -- 聊天模式
				adapter = "deepseek",
			},
			inline = { -- 行内编辑模式
				adapter = "deepseek",
			},
			cmd = { -- 命令行模式
				adapter = "deepseek",
			},
		},
		-- 适配器具体配置
		adapters = {
			http = {
				deepseek = function() -- deepseek适配器定义
					return require("codecompanion.adapters").extend("deepseek", {
						env = {
							api_key = "cmd:echo $DEEPSEEK_API_KEY", -- 从环境变量读取
						},
						schema = {
							model = {
								default = "deepseek-chat", -- 默认模型
							},
						},
					})
				end,
				gemini = function()
					return require("codecompanion.adapters").extend("gemini", {
						env = {
							api_key = "cmd:echo $GEMINI_API_KEY", -- 从环境变量读取
						},
						schema = {
							model = {
								default = "gemini-2.5-flash", -- 更新的模型
							},
						},
					})
				end,
				openai = function()
					return require("codecompanion.adapters").extend("openai", {
						env = {
							api_key = "cmd:echo $OPENAI_API_KEY", -- 从环境变量读取
						},
						schema = {
							model = {
								default = "gpt-4o", -- 默认模型
							},
						},
					})
				end,
				ollama = function()
					return require("codecompanion.adapters").extend("ollama", {
						env = {
							url = "http://192.168.5.225:11434",
						},
						schema = {
							model = {
								default = "qwen3-coder:30b", -- 默认模型
							},
							num_ctx = {
								default = 32768,
							},
						},
					})
				end,
			},
			acp = {
				gemini_cli = function()
					return require("codecompanion.adapters").extend("gemini_cli", {
						defaults = {
							auth_method = "oauth-personal", -- 使用 gemini-cli OAuth
						},
					})
				end,
			},
		},
		-- 预定义提示库
		prompt_library = {
			-- 代码解释
			["Explain Code"] = {
				interaction = "chat",
				description = "解释选中的代码",
				opts = {
					index = 1,
					is_slash_cmd = true,
					alias = "explain",
				},
				prompts = {
					{
						role = "user",
						content = "请详细解释以下代码的功能、逻辑和关键点，用中文回答：\n\n```{{filetype}}\n{{selection}}\n```",
						opts = { contains_code = true },
					},
				},
			},
			-- 代码优化
			["Optimize Code"] = {
				interaction = "inline",
				description = "优化选中的代码",
				opts = {
					index = 2,
					is_slash_cmd = true,
					alias = "opt",
				},
				prompts = {
					{
						role = "user",
						content = "请优化以下代码，提高性能、可读性和最佳实践，保持原有功能不变：\n\n```{{filetype}}\n{{selection}}\n```",
						opts = { contains_code = true },
					},
				},
			},
			-- 添加注释
			["Add Comments"] = {
				interaction = "inline",
				description = "为代码添加注释",
				opts = {
					index = 3,
					is_slash_cmd = true,
					alias = "comment",
				},
				prompts = {
					{
						role = "user",
						content = "请为以下代码添加详细的中文注释，解释每个重要部分的作用：\n\n```{{filetype}}\n{{selection}}\n```",
						opts = { contains_code = true },
					},
				},
			},
			-- 修复 Bug
			["Fix Bug"] = {
				interaction = "chat",
				description = "分析并修复代码中的问题",
				opts = {
					index = 4,
					is_slash_cmd = true,
					alias = "fix",
				},
				prompts = {
					{
						role = "user",
						content = "请分析以下代码中可能存在的问题并提供修复方案：\n\n```{{filetype}}\n{{selection}}\n```",
						opts = { contains_code = true },
					},
				},
			},
			-- 生成测试
			["Generate Tests"] = {
				interaction = "chat",
				description = "为代码生成测试用例",
				opts = {
					index = 5,
					is_slash_cmd = true,
					alias = "test",
				},
				prompts = {
					{
						role = "user",
						content = "请为以下代码生成完整的测试用例，包括正常情况、边界情况和异常情况：\n\n```{{filetype}}\n{{selection}}\n```",
						opts = { contains_code = true },
					},
				},
			},
			-- 名为"Generate a Commit Message"的提示
			["Generate a Commit Message"] = {
				interaction = "chat", -- 使用聊天策略
				description = "Generate a commit message", -- 描述
				opts = {
					index = 10, -- 排序位置
					is_default = true, -- 设为默认提示
					is_slash_cmd = true, -- 支持斜杠命令
					alias = "nxcmt", -- 快捷名称
					auto_submit = true, -- 自动提交
				},
				-- 提示内容定义
				prompts = {
					{
						role = "user", -- 用户角色
						content = function() -- 动态生成内容
							return string.format(
								[[
你是一位精通 Conventional Commits 的软件工程师和代码分析专家。
请基于下方提供的暂存区完整 git diff，提炼本次提交的主要意图，并生成一份可直接用于 git commit 的中文提交信息。

注意：
- 只输出最终提交信息
- 不允许输出解释、分析或思考过程
- 不允许输出 Markdown 标题（如 ###）
- 不允许输出代码块
- 必须严格按照指定结构输出
- 请优先根据跨文件主线变更概括提交意图，不要被局部实现细节、注释、示例文本、文档补充或重命名噪音误导
- 若代码变更与文档变更同时存在，应优先以代码主变更确定提交类型和范围
- 正文应聚焦于变更动机、方案和影响，不要逐文件罗列实现细节
- 关键变更点应概括模块级改动，不要抄写函数名列表，除非这些名称本身构成接口变更
- 解决方案应描述方案层面的修正思路，避免直接复述具体宏值、行级修改或代码字面量，除非这些字面量本身构成行为变更核心
- 下方 diff 仅作为输入材料，不要求复述或解释 diff

---

【输出格式】

提交信息必须严格包含以下三个部分，并按顺序输出：

提交头
正文
脚注

如果缺少任何一部分，视为错误输出。

---

【提交头】

格式：

类型(范围): 主题

类型必须从以下列表选择：

feat | fix | docs | style | refactor | perf | test | build | ci | chore | revert

类型选择规则：

- 修复错误行为、异常逻辑、边界问题 → fix
- 恢复被调试开关、条件编译、临时注释或保护代码屏蔽的既有逻辑 → fix
- 新增用户可感知能力或新接口 → feat
- 仅修改 README、注释、手册、说明文档等，不影响程序行为 → docs
- 修改提示词、规则文本、模板、策略文本、配置文案或其他会直接影响运行时输出行为的内容 → refactor
- 主要是结构调整、解耦、命名优化且无新增能力 → refactor
- 性能优化 → perf

范围规则：

- 范围应优先使用模块名、子系统名或稳定目录名
- 不要优先使用具体文件名作为范围，除非该文件本身就是独立模块
- 若无法确定精确模块，则使用更稳定、更上层的范围
- 示例范围：(log)、(heartbeat)、(network)、(storage)、(core)、(build)、(docs)

主题要求：

- 使用祈使句
- 首字母小写
- 不超过50个汉字
- 不包含实现细节
- 末尾不加标点

---

【正文】

提交头后必须空一行，然后输出正文。

正文必须包含以下四个小节，名称必须完全一致：

问题根源：
解决方案：
影响面：
关键变更点：

问题根源和解决方案应尽量基于 diff 可直接支持的信息表述，避免加入无法从 diff 明确证明的主观归因。

问题根源的推荐表述方式：
- “某逻辑仍处于调试保护状态”
- “某流程被条件分支屏蔽”
- “某行为未按预期进入正常处理路径”
- “某功能当前未生效/未触发”

解决方案的推荐表述方式：
- “关闭调试保护”
- “恢复正常处理路径”
- “使某逻辑重新生效”
- “恢复既有行为”

除非 diff 能直接证明存在错误配置、错误赋值或错误调用，否则不要使用以下表述：
- “错误地”
- “误”
- “异常配置”
- “误用”
- “被错误地设置”
- “常开状态”
- “恢复为正常状态”

影响面小节必须包含：

• 对用户：
• 对开发者：
• 潜在风险：

影响面要求：

- “对用户”描述用户可感知行为、稳定性、性能或体验变化
- “对开发者”描述维护方式、调试方式、调用方式或理解成本变化
- “潜在风险”应客观描述可能风险；若风险不明显，可写“风险有限”或“无明显新增风险”
- 不要轻易直接写“无”，除非 diff 明确表明完全没有风险

关键变更点必须包含 3–6 条，每条以：

•

开头。

关键变更点要求：

- 描述模块级改动，而不是逐行实现细节
- 优先总结行为变化、职责调整、接口变化、配置变化
- 不要复述整个 diff
- 若变更很小，可用更抽象的模块级表述补足到 3 条，但不得编造不存在的功能

---

【脚注】

正文后如果需要脚注，须与正文空一行。

只有当出现明确的不兼容变更时才输出脚注，例如：

- 公共 API 或函数签名变化
- 配置键或配置结构变化
- 默认行为变化且影响外部调用方式
- 数据结构或协议不兼容

如果满足以上条件，必须输出：

BREAKING CHANGE:

BREAKING CHANGE 后的说明可使用中文，需要描述影响和迁移方式。

以下情况不视为 BREAKING CHANGE：

- 修复 bug
- 恢复被调试代码屏蔽的原有逻辑
- 内部实现重构
- 调试行为变化
- 非公共接口变化

如果没有明确的不兼容变更，则不要输出脚注。

如果 diff 中存在 issue 线索，可使用：

Closes #
Refs !

---

【判定规则】

1 如果 diff 涉及多个不相关模块  
在正文开头说明：

检测到多关注点，建议拆分提交

然后仅总结主要变更。

2 如果 diff 很小或仅修改条件开关  
优先判断为 fix，而不是 feat。

3 如果无法确定影响范围  
使用更稳定的上层模块范围，并在正文中使用：

风险有限  
无明显变化

4 不允许省略任何结构。

5 如果改动对象位于代码或配置文件中，且其文本内容会直接影响程序、插件或模型的运行时输出行为，不应优先判定为 docs。
---

【输入】

git diff 内容如下：

~~~diff
%s
~~~

现在开始生成提交信息。
]],
								vim.fn.system("git diff --no-ext-diff --staged")
							)
						end,
						opts = {
							contains_code = true, -- 标记包含代码
						},
					},
				},
			},
		},
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
					auto_generate_title = true,
					title_generation_opts = {
						---Adapter for generating titles (defaults to current chat adapter)
						adapter = nil, -- "copilot"
						---Model for generating titles (defaults to current chat model)
						model = nil, -- "gpt-4o"
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
	-- 快捷键绑定
	keys = {
		{
			"<leader>dm", -- 快捷键组合
			function() -- 执行函数
				require("codecompanion").prompt("nxcmt") -- 触发nxcmt提示
			end,
			desc = "Generate commit message", -- 描述
			mode = "n", -- 普通模式生效
			noremap = true, -- 非递归映射
			silent = true, -- 静默执行
		},
		{ "<leader>di", "<cmd>CodeCompanionChat<cr>", desc = "CodeCompanionChat" },
		{ "<leader>da", "<cmd>CodeCompanionActions<cr>", desc = "CodeCompanion Actions" },
		{ "<leader>dg", "<cmd>CodeCompanionChat Toggle<cr>", desc = "Toggle CodeCompanion" },
		{ "<leader>dd", "<cmd>CodeCompanion<cr>", desc = "CodeCompanion inline", mode = { "n", "v" } },
		{ "<leader>dh", "<cmd>CodeCompanionHistory<cr>", desc = "CodeCompanion History" },
		-- 代码分析快捷键
		{
			"<leader>de",
			function()
				require("codecompanion").prompt("explain")
			end,
			desc = "Explain code",
			mode = "v",
		},
		{
			"<leader>do",
			function()
				require("codecompanion").prompt("opt")
			end,
			desc = "Optimize code",
			mode = "v",
		},
		{
			"<leader>dc",
			function()
				require("codecompanion").prompt("comment")
			end,
			desc = "Add comments",
			mode = "v",
		},
		{
			"<leader>dx",
			function()
				require("codecompanion").prompt("fix")
			end,
			desc = "AI Fix bug",
			mode = "v",
		},
		{
			"<leader>dt",
			function()
				require("codecompanion").prompt("test")
			end,
			desc = "Generate tests",
			mode = "v",
		},
	},
}
