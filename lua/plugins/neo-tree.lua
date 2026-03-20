-- 侧边文件树。
-- 1. 主要承担文件浏览、git 状态查看和目录切换，不和 dashboard 的“启动入口”职责混在一起。
-- 2. 跟随当前文件开启，这样在项目里切换 buffer 时树会自动对齐上下文。
local function on_popup_input_ready(args)
	-- 新建/重命名输入框默认退出插入，和整体键位习惯保持一致。
	vim.cmd("stopinsert")
	vim.keymap.set("i", "<esc>", vim.cmd.stopinsert, { noremap = true, buffer = args.bufnr })
end

local function order_by_mappings()
	return {
		["o"] = { "show_help", nowait = false, config = { title = "Order by", prefix_key = "o" } },
		["oc"] = { "order_by_created", nowait = false },
		["od"] = { "order_by_diagnostics", nowait = false },
		["om"] = { "order_by_modified", nowait = false },
		["on"] = { "order_by_name", nowait = false },
		["os"] = { "order_by_size", nowait = false },
		["ot"] = { "order_by_type", nowait = false },
	}
end

local function extend_mappings(base, extra)
	return vim.tbl_extend("force", base, order_by_mappings(), extra or {})
end

local default_component_configs = {
	container = {
		enable_character_fade = true,
	},
	indent = {
		indent_size = 2,
		padding = 1,
		with_markers = true,
		indent_marker = "│",
		last_indent_marker = "└",
		highlight = "NeoTreeIndentMarker",
		with_expanders = nil,
		expander_collapsed = "",
		expander_expanded = "",
		expander_highlight = "NeoTreeExpander",
	},
	icon = {
		folder_closed = "",
		folder_open = "",
		folder_empty = "󰜌",
		default = "*",
		highlight = "NeoTreeFileIcon",
	},
	modified = {
		symbol = "[+]",
		highlight = "NeoTreeModified",
	},
	name = {
		trailing_slash = false,
		use_git_status_colors = true,
		highlight = "NeoTreeFileName",
	},
	git_status = {
		symbols = {
			added = "✚",
			modified = "",
			deleted = "✖",
			renamed = "󰁕",
			untracked = "",
			ignored = "",
			unstaged = "󰄱",
			staged = "",
			conflict = "",
		},
	},
	file_size = {
		enabled = true,
		required_width = 64,
	},
	type = {
		enabled = true,
		required_width = 122,
	},
	last_modified = {
		enabled = true,
		required_width = 88,
	},
	created = {
		enabled = true,
		required_width = 110,
	},
	symlink_target = {
		enabled = false,
	},
}

local window_mappings = {
	["<space>"] = { "toggle_node", nowait = false },
	["<2-LeftMouse>"] = "open",
	["<cr>"] = "open",
	["<esc>"] = "cancel",
	["P"] = { "toggle_preview", config = { use_float = true, use_image_nvim = true } },
	["l"] = "focus_preview",
	["S"] = "open_split",
	["s"] = "open_vsplit",
	["t"] = "open_tabnew",
	["w"] = "open_with_window_picker",
	["C"] = "close_node",
	["z"] = "close_all_nodes",
	["a"] = { "add", config = { show_path = "none" } },
	["A"] = "add_directory",
	["d"] = "delete",
	["r"] = "rename",
	["y"] = "copy_to_clipboard",
	["x"] = "cut_to_clipboard",
	["p"] = "paste_from_clipboard",
	["c"] = "copy",
	["m"] = "move",
	["q"] = "close_window",
	["R"] = "refresh",
	["?"] = "show_help",
	["<"] = "prev_source",
	[">"] = "next_source",
	["i"] = "show_file_details",
}

local filesystem_mappings = extend_mappings({
	["<bs>"] = "navigate_up",
	["."] = "set_root",
	["H"] = "toggle_hidden",
	["/"] = "fuzzy_finder",
	["D"] = "fuzzy_finder_directory",
	["#"] = "fuzzy_sorter",
	["f"] = "filter_on_submit",
	["<c-x>"] = "clear_filter",
	["[g"] = "prev_git_modified",
	["]g"] = "next_git_modified",
}, {
	["og"] = { "order_by_git_status", nowait = false },
})

local buffer_mappings = extend_mappings({
	["bd"] = "buffer_delete",
	["<bs>"] = "navigate_up",
	["."] = "set_root",
})

local git_status_mappings = extend_mappings({
	["A"] = "git_add_all",
	["gu"] = "git_unstage_file",
	["ga"] = "git_add_file",
	["gr"] = "git_revert_file",
	["gc"] = "git_commit",
	["gp"] = "git_push",
	["gg"] = "git_commit_and_push",
})

return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	keys = {
		{ "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle file explorer" },
		{ "<leader>E", "<cmd>Neotree focus<cr>", desc = "Focus file explorer" },
		{ "<leader>ge", "<cmd>Neotree git_status<cr>", desc = "Explorer git status" },
	},
	opts = {
		close_if_last_window = false,
		popup_border_style = "rounded",
		enable_git_status = true,
		enable_diagnostics = true,
		open_files_do_not_replace_types = { "terminal", "trouble", "qf" },
		sort_case_insensitive = false,
		sort_function = nil,
		event_handlers = {
			{
				event = "neo_tree_popup_input_ready",
				handler = on_popup_input_ready,
			},
		},
		default_component_configs = default_component_configs,
		commands = {},
		window = {
			position = "left",
			width = 40,
			mapping_options = {
				noremap = true,
				nowait = true,
			},
			mappings = window_mappings,
		},
		nesting_rules = {},
		filesystem = {
			filtered_items = {
				visible = false,
				hide_dotfiles = true,
				hide_gitignored = true,
				hide_hidden = true,
				hide_by_name = {},
				hide_by_pattern = {},
				always_show = {},
				never_show = {},
				never_show_by_pattern = {},
			},
			follow_current_file = {
				enabled = true,
				-- 切 buffer 时允许折叠无关目录，避免大项目树被不断撑开。
				leave_dirs_open = false,
			},
			group_empty_dirs = false,
			hijack_netrw_behavior = "open_default",
			use_libuv_file_watcher = false,
			window = {
				mappings = filesystem_mappings,
			},
			commands = {},
		},
		buffers = {
			follow_current_file = {
				enabled = true,
				leave_dirs_open = false,
			},
			group_empty_dirs = true,
			show_unloaded = true,
			window = {
				mappings = buffer_mappings,
			},
		},
		git_status = {
			window = {
				position = "float",
				mappings = git_status_mappings,
			},
		},
	},
}
