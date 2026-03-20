-- CodeCompanion 高频中文 prompt 模板。
-- 重点是把经常要重复描述的中文约束固化下来。
local M = {}

local function build_commit_message_prompt()
	local staged_diff = vim.fn.system("git diff --no-ext-diff --staged")
	if vim.v.shell_error ~= 0 then
		return "无法读取暂存区 diff，请先确认当前目录是 git 仓库，并且存在可读取的暂存改动。"
	end

	if staged_diff:gsub("%s+", "") == "" then
		return "暂存区为空，无法生成 commit message。请先执行 git add 后再试。"
	end

	local staged_stat = vim.fn.system("git diff --no-ext-diff --staged --stat")
	if vim.v.shell_error ~= 0 then
		staged_stat = "无法读取 diff stat"
	end

	return string.format(
		[[
你是一位精通 Conventional Commits 的软件工程师。
请基于下方提供的暂存区变更摘要与完整 git diff，生成一份“便于人工继续修改”的中文 commit message 草稿。

要求：
- 只输出提交信息草稿本身，不要输出解释、分析、思考过程、标题或代码块
- 优先概括跨文件的主线变更，不要被注释、示例文本、文档补充或重命名噪音误导
- 若代码变更与文档变更同时存在，应优先根据代码主变更确定类型和范围
- 仅根据 diff 中可以直接支持的信息写结论；不确定时使用更保守的表述，不要脑补原因
- 正文聚焦“动机、改动、影响”，不要逐文件复述实现细节
- 这是草稿，措辞应简洁、稳定，方便后续手动修改

输出格式：

类型(范围): 主题

`动机：` 后不要空行，下一行直接开始 `- ` 列表；`改动：` 和 `影响：` 同理。
各小节之间保留一个空行。

动机：
- ...

改动：
- ...

影响：
- ...

可选脚注：
- 只有在存在明确的不兼容变更时，才额外输出 BREAKING CHANGE: ...
- 如果 diff 中有明确的 issue 编号，再输出 Closes #... 或 Refs #...
- 没有这些信息时，不要输出任何脚注
- 正文中的列表项统一使用 `- ` 作为前缀，不要使用 `•`、`*`、`1.` 或其他列表符号

类型必须从以下列表选择：
feat | fix | docs | style | refactor | perf | test | build | ci | chore | revert

类型选择规则：
- 修复错误行为、异常逻辑、边界问题，或恢复被调试/保护逻辑屏蔽的既有行为 -> fix
- 新增用户可感知能力或新接口 -> feat
- 仅修改 README、注释、手册等且不影响程序行为 -> docs
- 修改提示词、规则文本、模板、策略文本、配置文案等时：
  - 如果主要是在修正输出偏差、错误行为或错误路径 -> fix
  - 如果主要是在新增能力、扩展工作流或增加新场景支持 -> feat
  - 如果主要是在整理结构、统一表达或降低维护成本 -> refactor
- 主要是结构调整、解耦、命名优化且无新增能力 -> refactor
- 性能优化 -> perf

范围规则：
- 优先使用模块名、子系统名或稳定目录名
- 不要优先使用具体文件名作为范围，除非该文件本身就是独立模块
- 若无法确定精确模块，可使用更稳定、更上层的范围，如 core、ui、build、docs

主题要求：
- 使用简洁中文，避免空泛词语
- 主题优先描述行为变化或改动目的，少用“调整逻辑”“优化处理”这类泛词
- 不超过 50 个汉字
- 不包含实现细节
- 末尾不加标点

正文要求：
- `动机` 说明为什么要做这次修改，优先写变更前的问题、限制、使用痛点或上下文；如果 diff 无法证明根因，就不要写成确定性归因
- 如果本次改动的核心在于模块职责、链路边界、状态切换条件或调用时机的调整，`动机` 或 `影响` 中应明确点出这种边界变化
- `改动` 概括这次主要调整了什么，聚焦模块级改动、行为调整或配置变化，不要堆砌字面量、函数名或逐行修改
- 若 diff 中存在直接改变运行路径的条件判断、提前返回、开关分支或保护逻辑，`改动` 中应优先概括这些行为变化，因为它们通常决定了本次提交的实际效果
- `影响` 描述改完之后的行为变化、结果、维护收益或风险；如果风险不明显，可写“风险有限”
- 如果改动的价值在于避免串扰、误触发、重复执行、错误传播或隐式耦合，`影响` 中应明确写出被避免的副作用
- 如果无法从 diff 判断用户影响，可优先描述行为变化或维护影响，不要空泛写“提升体验”“增强稳定性”
- 当 diff 只能支持“调整处理路径、收紧边界、减少干预、避免副作用”等表述时，不要写成“已恢复正常”“已解决”“可正常工作”等强结论，除非 diff 能直接证明
- 每个小节写 1-3 条即可；如果改动很小，不要为了凑数量编造内容
- 你的目标是帮助未来查看 git log 时快速回忆“为什么改、改了什么、改完有什么作用”，请优先服务这个目标，而不是追求过度正式的总结口吻

补充判定：
- 如果 diff 涉及多个不相关关注点，优先总结主线变更，并在 `影响` 中提示“建议拆分提交”
- 如果 diff 很小或主要是开关/保护逻辑调整，优先考虑 `fix`
- 如果改动位于代码或配置文件，且文本变化会直接影响程序、插件或模型的运行时输出行为，不应优先判定为 `docs`
---

【输入】

变更摘要如下：

%s

完整 git diff 如下：

~~~diff
%s
~~~

现在开始生成提交信息。
]],
		staged_stat,
		staged_diff
	)
end

M["Explain Code"] = {
	interaction = "chat",
	description = "解释选中的代码",
	opts = {
		index = 1,
		is_slash_cmd = true,
		alias = "explain_cn",
		auto_submit = true,
	},
	prompts = {
		{
			role = "user",
			content = "请详细解释以下代码的功能、逻辑和关键点。回答必须全部使用简体中文，不要输出英文解释、英文标题或英文要点；如需引用代码标识符，可保留原始标识符。\n\n```{{filetype}}\n{{selection}}\n```",
			opts = { contains_code = true },
		},
	},
}

M["Optimize Code"] = {
	interaction = "inline",
	description = "优化选中的代码",
	opts = {
		index = 2,
		is_slash_cmd = true,
		alias = "opt_cn",
	},
	prompts = {
		{
			role = "user",
			content = "请优化以下代码，提高性能、可读性和最佳实践，保持原有功能不变。除代码本身的语法关键字、库名、API 名称外，说明文字必须全部使用简体中文；如果需要新增或修改注释，注释也必须是简体中文。\n\n```{{filetype}}\n{{selection}}\n```",
			opts = { contains_code = true },
		},
	},
}

M["Add Comments"] = {
	interaction = "inline",
	description = "为代码添加注释",
	opts = {
		index = 3,
		is_slash_cmd = true,
		alias = "comment_cn",
	},
	prompts = {
		{
			role = "user",
			content = "请为以下代码添加详细的简体中文注释，解释每个重要部分的作用。所有新增注释都必须使用简体中文，不要输出英文注释；除代码本身必要的关键字、类型名、函数名、库名外，不要加入英文说明。\n\n```{{filetype}}\n{{selection}}\n```",
			opts = { contains_code = true },
		},
	},
}

M["Fix Bug"] = {
	interaction = "chat",
	description = "分析并修复代码中的问题",
	opts = {
		index = 4,
		is_slash_cmd = true,
		alias = "fix_cn",
		auto_submit = true,
	},
	prompts = {
		{
			role = "user",
			content = "请分析以下代码中可能存在的问题并提供修复方案。回答必须全部使用简体中文，不要输出英文分析、英文标题或英文列表；如需给出代码修改建议，代码外的说明文字必须为中文。\n\n```{{filetype}}\n{{selection}}\n```",
			opts = { contains_code = true },
		},
	},
}

M["Generate Tests"] = {
	interaction = "chat",
	description = "为代码生成测试用例",
	opts = {
		index = 5,
		is_slash_cmd = true,
		alias = "test_cn",
		auto_submit = true,
	},
	prompts = {
		{
			role = "user",
			content = "请为以下代码生成完整的测试用例，包括正常情况、边界情况和异常情况。说明文字、测试意图和必要注释必须全部使用简体中文；仅代码语法、断言 API、库名和标识符可以保留原文。\n\n```{{filetype}}\n{{selection}}\n```",
			opts = { contains_code = true },
		},
	},
}

M["Generate a Commit Message"] = {
	interaction = "chat",
	description = "Generate a commit message",
	opts = {
		index = 10,
		is_default = true,
		is_slash_cmd = true,
		alias = "commit_cn",
		auto_submit = true,
	},
	prompts = {
		{
			role = "user",
			content = build_commit_message_prompt,
			opts = {
				contains_code = true,
			},
		},
	},
}

return M
