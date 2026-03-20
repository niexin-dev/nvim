-- 跨环境剪贴板桥接。
-- 1. 默认同时接入 unnamed / unnamedplus。
-- 2. WSL 优先用 win32yank，SSH 优先用 OSC52；其余环境走 Neovim 默认行为。
local function setup_wsl_clipboard()
	vim.g.clipboard = {
		name = "win32yank-wsl",
		copy = {
			["+"] = "win32yank.exe -i --crlf",
			["*"] = "win32yank.exe -i --crlf",
		},
		paste = {
			["+"] = "win32yank.exe -o --lf",
			["*"] = "win32yank.exe -o --lf",
		},
		cache_enabled = true,
	}
end

local function setup_osc52_clipboard()
	local function osc52_paste()
		local content = vim.fn.getreg("")
		return vim.split(content, "\n")
	end

	vim.g.clipboard = {
		name = "OSC 52",
		copy = {
			["+"] = require("vim.ui.clipboard.osc52").copy("+"),
			["*"] = require("vim.ui.clipboard.osc52").copy("*"),
		},
		paste = {
			["+"] = osc52_paste,
			["*"] = osc52_paste,
		},
	}
end

vim.opt.clipboard:append({ "unnamed", "unnamedplus" })

if vim.fn.has("wsl") == 1 then
	setup_wsl_clipboard()
	return
end

if vim.env.SSH_TTY ~= nil then
	-- 远程会话里优先保证“能复制出去”，哪怕粘贴能力只能走寄存器回退。
	setup_osc52_clipboard()
end
