-- 全局基础键位。
-- 1. 这里只放和具体插件无关、几乎任何会话都想保留的高频映射。
-- 2. 插件专属键位尽量放在各自的插件规格里，方便按模块查找和懒加载。
----------------------------------------------------------------------
--  Leader Key 设置
----------------------------------------------------------------------
vim.g.mapleader = ","
vim.g.maplocalleader = ","

----------------------------------------------------------------------
--  插入模式映射
----------------------------------------------------------------------
-- 插入模式按 "jk" 快速切换到 Normal 模式
vim.keymap.set("i", "jk", "<ESC>")

----------------------------------------------------------------------
--  可视模式映射
----------------------------------------------------------------------
-- 可视模式：将所选行向下移动一行
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")

-- 可视模式：将所选行向上移动两行
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

----------------------------------------------------------------------
--  Normal 模式映射
----------------------------------------------------------------------

-- LSP 重命名
vim.keymap.set("n", "<leader>ln", function()
	vim.lsp.buf.rename()
end, { desc = "LSP Rename" })
vim.keymap.set("i", "<leader>lS", function()
	vim.lsp.buf.signature_help({ border = "rounded" })
end, { desc = "LSP Signature Help" })

-- 在当前文件所在目录创建新文件（自动填充路径）
vim.keymap.set("n", "<leader>N", ':new <C-R>=expand("%:p:h") . "/" <CR>', { desc = "New file in cwd" })

-- 诊断跳转
vim.keymap.set("n", "<leader>jd", function()
	vim.diagnostic.jump({ count = 1, float = false })
end, { desc = "Jump to next diagnostic" })
vim.keymap.set("n", "<leader>kd", function()
	vim.diagnostic.jump({ count = -1, float = false })
end, { desc = "Jump to previous diagnostic" })

----------------------------------------------------------------------
--  屏幕行导航（处理换行后的多行显示）
----------------------------------------------------------------------
-- 无计数时按屏幕行移动，有计数时保留原生行为
vim.keymap.set({ "n", "v" }, "k", function()
	return vim.v.count == 0 and "gk" or "k"
end, { expr = true, noremap = true, silent = true })

-- j 映射为 gj
vim.keymap.set({ "n", "v" }, "j", function()
	return vim.v.count == 0 and "gj" or "j"
end, { expr = true, noremap = true, silent = true })

----------------------------------------------------------------------
--  更好的缩进：操作后保持可视模式
----------------------------------------------------------------------
vim.keymap.set("v", "<", "<gv", { desc = "Indent left" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right" })

----------------------------------------------------------------------
-- 清除搜索高亮
----------------------------------------------------------------------
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- diff visual sync
vim.keymap.set("v", "do", ":'<,'>diffget<CR>", { desc = "diff get selection" })
vim.keymap.set("v", "dp", ":'<,'>diffput<CR>", { desc = "diff put selection" })
