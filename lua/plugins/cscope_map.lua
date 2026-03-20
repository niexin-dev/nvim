-- C/C++ 代码检索入口。
-- 1. 只有在 C/C++ 文件里才有意义，因此按 filetype 懒加载。
-- 2. 有 UI 时优先接 fzf-lua，没有 UI 或 picker 不可用时退回 quickfix，兼顾交互和稳妥。
return {
	"dhananjaylatkar/cscope_maps.nvim",
	ft = { "c", "cpp" },

	dependencies = {
		"ibhagwan/fzf-lua", -- optional [for picker="fzf-lua"]
		"nvim-lua/plenary.nvim",
	},
	-- config = function()
	--     require("cscope_maps").setup({
	--         skip_input_prompt = true,     -- "true" doesn't ask for input
	--         cscope = {
	--             picker = "fzf-lua"
	--         }
	--     })
	-- end,
	keys = {
		{ "<leader>cj", "<cmd>CsStackView open down<cr>", desc = "Cscope StackView Down" },
		{ "<leader>ck", "<cmd>CsStackView open up<cr>", desc = "Cscope StackView Up" },
	},
	opts = {
		skip_input_prompt = true, -- "true" doesn't ask for input
		cscope = {
			picker = (function()
				if #vim.api.nvim_list_uis() == 0 then
					return "quickfix"
				end
				local ok = pcall(require, "fzf-lua")
				return ok and "fzf-lua" or "quickfix"
			end)(),
			db_build_cmd = { script = "default", args = { "-bqR" } },
		},
	},
}
