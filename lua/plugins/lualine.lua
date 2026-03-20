-- 状态栏配置。
-- 1. 走 VeryLazy，避免空启动时和 dashboard 抢首屏时间。
-- 2. lualine_c 里有一段自定义当前位置逻辑，优先 navic，其次 treesitter。
-- 3. 这里必须按窗口缓存，不能按全局缓存，否则多窗口下会出现符号串位。
return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	event = "VeryLazy",
	opts = {
		icons_enabled = true,
		theme = "tokyonight",
		component_separators = { left = "", right = "" },
		section_separators = { left = "", right = "" },
		disabled_filetypes = {
			statusline = {},
			winbar = {},
		},
		ignore_focus = {},
		always_divide_middle = true,
		always_show_tabline = true,
		globalstatus = false,
		refresh = {
			statusline = 300,
			tabline = 300,
			winbar = 300,
		},
		sections = {
			lualine_a = { "mode" },
			lualine_b = { "branch", "diff", "diagnostics" },
			lualine_c = {
				{ "filename", path = 1 },
				(function()
					local uv = vim.uv or vim.loop
					local cache = {}
					local update_interval = 200

					local function now_ms()
						if uv and uv.now then
							return uv.now()
						end
						return math.floor(vim.loop.hrtime() / 1000000)
					end

					local function treesitter_symbol(bufnr)
						local ok_node, node = pcall(vim.treesitter.get_node, { bufnr = bufnr })
						if not ok_node or not node then
							return ""
						end

						local cur = node
						while cur do
							local t = cur:type()
							if t:find("function", 1, true) or t:find("method", 1, true) then
								local text = vim.treesitter.get_node_text(cur, bufnr) or ""
								local first = text:match("([^\n]+)") or ""
								local before_params = first:match("^(.-)%s*%(") or first
								local name = before_params:match("([%w_~]+)%s*$")
								return name and name ~= "" and ("fn:" .. name) or ""
							end

							cur = cur:parent()
						end

						return ""
					end

					return function()
						-- statusline 渲染时要取“正在被绘制的窗口”，而不是简单取当前窗口。
						local winid = tonumber(vim.g.statusline_winid) or vim.api.nvim_get_current_win()
						if not vim.api.nvim_win_is_valid(winid) then
							return ""
						end

						local bufnr = vim.api.nvim_win_get_buf(winid)
						if vim.bo[bufnr].buftype ~= "" then
							cache[winid] = nil
							return ""
						end

						local state = cache[winid]
						local now = now_ms()
						if state and state.bufnr == bufnr and (now - state.last_update) < update_interval then
							return state.value
						end

						local value = vim.api.nvim_win_call(winid, function()
							local ok_navic, navic = pcall(require, "nvim-navic")
							if ok_navic and navic.is_available() then
								local location = navic.get_location()
								if location and location ~= "" then
									return location
								end
							end

							-- navic 不可用时退回到 treesitter，至少给出当前函数名。
							local ok_parser = pcall(vim.treesitter.get_parser, bufnr)
							if ok_parser then
								return treesitter_symbol(bufnr)
							end

							return ""
						end)

						cache[winid] = {
							bufnr = bufnr,
							last_update = now,
							value = value,
						}
						return value
					end
				end)(),
			},
			lualine_x = { "encoding", "fileformat", "filetype" },
			lualine_y = { "progress" },
			lualine_z = { "location" },
		},
		inactive_sections = {
			lualine_a = {},
			lualine_b = {},
			lualine_c = { { "filename", path = 1 } },
			lualine_x = { "location" },
			lualine_y = {},
			lualine_z = {},
		},
		tabline = {},
		winbar = {},
		inactive_winbar = {},
		extensions = {},
	},
}
