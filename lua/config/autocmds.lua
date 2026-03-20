-- 全局自动命令。
-- 目前只保留真正跨插件、跨语言都成立的编辑器行为。
local group = vim.api.nvim_create_augroup("UserCoreAutocmds", { clear = true })

vim.api.nvim_create_autocmd("BufReadPost", {
	group = group,
	pattern = "*",
	desc = "打开文件时恢复上次离开的位置",
	callback = function(args)
		if vim.bo[args.buf].buftype ~= "" then
			return
		end

		local name = vim.api.nvim_buf_get_name(args.buf)
		if vim.fn.filereadable(name) ~= 1 then
			return
		end

		local last_pos = vim.fn.line([['"]], args.buf)
		local line_count = vim.api.nvim_buf_line_count(args.buf)
		if last_pos > 1 and last_pos <= line_count then
			vim.api.nvim_win_set_cursor(0, { last_pos, 0 })
		end
	end,
})
