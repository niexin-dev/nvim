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
					local cache = ""
					local last_update = -1000
					local update_interval = 200

					local function now_ms()
						if uv and uv.now then
							return uv.now()
						end
						return math.floor(vim.loop.hrtime() / 1000000)
					end

					local function treesitter_symbol()
						local ok_node, node = pcall(vim.treesitter.get_node, { bufnr = 0 })
						if not ok_node or not node then
							return ""
						end

						local cur = node
						while cur do
							local t = cur:type()
							if t:find("function", 1, true) or t:find("method", 1, true) then
								local text = vim.treesitter.get_node_text(cur, 0) or ""
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
						if vim.bo.buftype ~= "" then
							return ""
						end

						local now = now_ms()
						if (now - last_update) < update_interval then
							return cache
						end
						last_update = now

						local ok_navic, navic = pcall(require, "nvim-navic")
						if ok_navic and navic.is_available() then
							local location = navic.get_location()
							if location and location ~= "" then
								cache = location
								return cache
							end
						end

						local ok_parser = pcall(vim.treesitter.get_parser, 0)
						if ok_parser then
							cache = treesitter_symbol()
							return cache
						end

						cache = ""
						return cache
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
