-- 全局诊断展示策略。
-- 把诊断 UI 基线放在核心配置层，避免由某个显示插件反向修改全局状态。
vim.diagnostic.config({
	virtual_text = false,
})
