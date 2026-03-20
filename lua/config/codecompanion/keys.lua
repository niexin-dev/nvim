-- CodeCompanion 快捷键集合。
local function prompt(alias)
	return function()
		require("codecompanion").prompt(alias)
	end
end

return {
	{
		"<leader>am",
		prompt("commit_cn"),
		desc = "Generate commit message",
		mode = "n",
		noremap = true,
		silent = true,
	},
	{ "<leader>ai", "<cmd>CodeCompanionChat<cr>", desc = "AI Chat" },
	{ "<leader>aa", "<cmd>CodeCompanionActions<cr>", desc = "AI Actions" },
	{ "<leader>ag", "<cmd>CodeCompanionChat Toggle<cr>", desc = "Toggle AI Chat" },
	{ "<leader>ae", "<cmd>CodeCompanion<cr>", desc = "AI Inline", mode = { "n", "v" } },
	{ "<leader>ah", "<cmd>CodeCompanionHistory<cr>", desc = "AI History" },
	{ "<leader>ax", prompt("explain_cn"), desc = "Explain code", mode = "v" },
	{ "<leader>ao", prompt("opt_cn"), desc = "Optimize code", mode = "v" },
	{ "<leader>ac", prompt("comment_cn"), desc = "Add comments", mode = "v" },
	{ "<leader>af", prompt("fix_cn"), desc = "AI Fix bug", mode = "v" },
	{ "<leader>ar", prompt("test_cn"), desc = "Generate tests", mode = "v" },
}
