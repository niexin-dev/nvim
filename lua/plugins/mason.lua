local tools = {
	"clang-format", -- C/C++ 格式化工具
	"mbake", -- Makefile format linter
	"prettierd", -- 更快的 Prettier 守护进程
	"shellcheck", -- Shell 脚本 linter
	"shfmt", -- Shell 脚本格式化工具
	"stylua", -- Lua 格式化工具
	"isort", -- Python import 排序工具
	"black", -- Python 代码格式化工具
	"ruff", -- Python lint / fix 工具
	-- taplo 由下方 LSP 安装，确保 CLI 与服务器一并提供
}

local servers = {
	"bashls", -- nvim-lspconfig 中 bash-language-server 的名称是 bashls
	"clangd",
	"lua_ls", -- nvim-lspconfig 中 lua-language-server 的名称是 lua_ls
	"marksman",
	"taplo", -- 这会安装 taplo CLI 工具和 LSP 服务器
	"cmake",
	"vtsls",
	"eslint",
	"tailwindcss",
	"jsonls",
	"basedpyright",
	"ruff",
}

-- ===========================================================
-- Mason 镜像检测 + 切换（只在 Smart 命令调用时执行）
-- ===========================================================
local OFFICIAL_DOWNLOAD_TEMPLATE = "https://github.com/%s/releases/download/%s/%s"
local MIRROR_DOWNLOAD_TEMPLATE = "https://ghproxy.com/https://github.com/%s/releases/download/%s/%s"

local function apply_mason_download_template(use_mirror)
	local ok, mason_settings = pcall(require, "mason.settings")
	if not ok then
		return
	end

	mason_settings.set({
		github = {
			download_url_template = use_mirror and MIRROR_DOWNLOAD_TEMPLATE or OFFICIAL_DOWNLOAD_TEMPLATE,
		},
	})
end

local function setup_mason_env()
	-- 没有 curl 就直接放弃检测，避免卡死
	if vim.fn.executable("curl") ~= 1 then
		return
	end

	-- 尝试访问 GitHub（HEAD 请求，超时 2 秒）
	local job = vim.system({ "curl", "-I", "--max-time", "2", "https://github.com" }, { text = true })
	local result = job:wait()

	if result.code == 0 then
		-- 🎉 GitHub 可访问 → 使用官方下载模板
		apply_mason_download_template(false)
		vim.notify("[mason] GitHub 可访问，使用官方下载源。", vim.log.levels.INFO)
	else
		-- 🚧 GitHub 无法访问 → 切换到 ghproxy 下载模板
		apply_mason_download_template(true)
		vim.notify("[mason] GitHub 无法访问，已切换 ghproxy 下载源。", vim.log.levels.WARN)
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
			-- github 下载模板由 Smart 命令按网络状态动态切换
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
					-- 补全阶段不能做同步 refresh，否则会阻塞命令行输入
					local registry = require("mason-registry")
					local ok, all_pkg_names = pcall(registry.get_all_package_names)
					if not ok then
						return {}
					end
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
