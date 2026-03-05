local tools = {
	"clang-format", -- C/C++ 格式化工具
	"mbake", -- Makefile format linter
	"prettierd", -- 更快的 Prettier 守护进程
	"shellcheck", -- Shell 脚本 linter
	"shfmt", -- Shell 脚本格式化工具
	"stylua", -- Lua 格式化工具
	"isort", -- Python import 排序工具
	"black", -- Python 代码格式化工具
	-- taplo 由下方 LSP 安装，确保 CLI 与服务器一并提供
}

local servers = {
	"bashls", -- nvim-lspconfig 中 bash-language-server 的名称是 bashls
	"clangd",
	"lua_ls", -- nvim-lspconfig 中 lua-language-server 的名称是 lua_ls
	"marksman",
	"taplo", -- 这会安装 taplo CLI 工具和 LSP 服务器
	"cmake",
}

-- ===========================================================
-- Mason 镜像检测 + 切换（只在 Smart 命令调用时执行）
-- ===========================================================
local function setup_mason_env()
	-- 没有 curl 就直接放弃检测，避免卡死
	if vim.fn.executable("curl") ~= 1 then
		return
	end

	-- 尝试访问 GitHub（HEAD 请求，超时 0.5 秒）
	local job = vim.system({ "curl", "-I", "--max-time", "0.5", "https://github.com" }, { text = true })
	local result = job:wait()

	if result.code == 0 then
		-- 🎉 GitHub 可访问 → 使用官方源
		vim.env.MASON_REGISTRY = nil
		vim.env.MASON_MIRROR = nil
		vim.notify("[mason] GitHub 可访问，使用官方源。", vim.log.levels.INFO)
	else
		-- 🚧 GitHub 无法访问 → 切换到国内镜像
		vim.env.MASON_REGISTRY = "https://registry.npmmirror.com/mason-registry/latest"
		vim.env.MASON_MIRROR = "https://ghproxy.com/https://github.com"
		vim.notify("[mason] GitHub 无法访问，已自动切换国内镜像。", vim.log.levels.WARN)
	end
end

return {
	{
		"williamboman/mason.nvim",
		cmd = { "Mason", "MasonInstall", "MasonUpdate" },
		-- mason.nvim 负责提供统一的安装界面与基础设施
		opts = {
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
			-- 不在这里改 registries / github，保持默认，由环境变量控制
		},

		-- ⭐ 在 config 里定义 Smart 命令：
		--   * 不会在 LSP 启动时自动检测
		--   * 只有用户调用 Smart 命令时才检测 + 切换
		config = function(_, opts)
			require("mason").setup(opts)

			local api = require("mason.api.command")

			-- :MasonSmart -> 先检测环境，再打开 Mason UI
			vim.api.nvim_create_user_command("MasonSmart", function()
				setup_mason_env()
				api.Mason()
			end, {
				desc = "检测网络并打开 Mason UI",
				nargs = 0,
			})

			-- :MasonInstallSmart xxx yyy
			-- 简化版：只支持最常见的 “包名列表”，暂不支持 --force 之类参数
			vim.api.nvim_create_user_command("MasonInstallSmart", function(cmd_opts)
				setup_mason_env()
				api.MasonInstall(cmd_opts.fargs)
			end, {
				desc = "检测网络并安装 Mason 包（简单参数版）",
				nargs = "+",
				complete = function(arg_lead)
					-- 复用 Mason 自己的补全逻辑（简化：只做包名补全）
					local registry = require("mason-registry")
					registry.refresh()
					local all_pkg_names = registry.get_all_package_names()
					local matches = {}
					for _, name in ipairs(all_pkg_names) do
						if name:find("^" .. vim.pesc(arg_lead)) then
							table.insert(matches, name)
						end
					end
					return matches
				end,
			})

			-- :MasonUpdateSmart -> 先检测，再更新 registry
			vim.api.nvim_create_user_command("MasonUpdateSmart", function()
				setup_mason_env()
				api.MasonUpdate()
			end, {
				desc = "检测网络并更新 Mason registry",
				nargs = 0,
			})
		end,
	},

	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "williamboman/mason.nvim" },
		cmd = { "MasonToolsInstall", "MasonToolsUpdate", "MasonToolsClean" },
		-- mason-tool-installer.nvim 用于确保通用开发工具按需安装与更新
		opts = {
			ensure_installed = tools,
			run_on_start = false,
			auto_update = false,
		},
	},

	{
		"williamboman/mason-lspconfig.nvim",
		-- 与 nvim-lspconfig 共用同一组延迟事件，声明依赖只会确保加载顺序，不会提前触发任一插件
		-- 修复lsp.log中的警告“clangd does not have a configuration”
		dependencies = { "neovim/nvim-lspconfig" },
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			-- 这里只放 nvim-lspconfig 支持的 LSP 服务器名称
			ensure_installed = servers,
		},
	},
}
