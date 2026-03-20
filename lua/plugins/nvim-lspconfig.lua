-- LSP 主入口。
-- 1. 只在真正进入文件缓冲区时加载，避免空启动时提前拉起整条语言服务链。
-- 2. 这里手写了一份 blink.cmp 的 completion capability 镜像，目的不是“复制配置”，
--    而是避免普通文件打开时为了拿 capability 就把 blink.cmp 整体提前加载。
-- 3. JSON Schema 通过 schemastore 按需获取，避免把 SchemaStore 放进常规 BufRead 热路径。
return {
	"neovim/nvim-lspconfig",
	-- 仅在读取 / 创建文件缓冲区时加载，避免在启动时抢占资源
	event = { "BufReadPre", "BufNewFile" },

	keys = {
		{
			"<leader>lh",
			function()
				if vim.fn.exists(":LspClangdSwitchSourceHeader") == 2 then
					vim.cmd.LspClangdSwitchSourceHeader()
					return
				end
				vim.notify("clangd 未就绪，无法切换头/源文件", vim.log.levels.WARN)
			end,
			desc = "LSP Switch Source/Header (C/C++)",
		},
	},

	config = function()
		vim.lsp.log.set_level("ERROR")
		local capabilities = require("config.lsp_capabilities").get()
		local js_ts_inlay_hints = {
			parameterNames = { enabled = "literals" },
			parameterTypes = { enabled = true },
			variableTypes = { enabled = true },
			propertyDeclarationTypes = { enabled = true },
			functionLikeReturnTypes = { enabled = true },
			enumMemberValues = { enabled = true },
		}

		vim.lsp.config("*", {
			capabilities = capabilities,
		})

		local stylua_cfg = vim.lsp.config["stylua"]
		if stylua_cfg then
			-- stylua 在这里只保留 formatter 能力，不把它作为常驻 LSP 自动启动。
			stylua_cfg.autostart = false
			stylua_cfg.cmd = nil
		end

		local uv = vim.uv or vim.loop
		local json_schemas

		local function get_json_schemas()
			-- schemastore 只在 jsonls 真正初始化配置时才读取一次，后续走缓存。
			if json_schemas ~= nil then
				return json_schemas or nil
			end

			local ok_schemastore, schemastore = pcall(require, "schemastore")
			if not ok_schemastore then
				json_schemas = false
				return nil
			end

			local ok_schemas, schemas = pcall(schemastore.json.schemas)
			if not ok_schemas then
				json_schemas = false
				return nil
			end

			json_schemas = schemas
			return json_schemas
		end

		vim.lsp.config["clangd"] = {
			cmd = {
				"clangd",
				"--background-index",
				"--clang-tidy",
				"--completion-style=detailed",
				"--function-arg-placeholders",
				"--header-insertion=never",
			},
			offset_encoding = "utf-8",
			init_options = {
				clangdFileStatus = true,
			},
			root_markers = {
				"compile_commands.json",
				"compile_flags.txt",
				".clangd",
				".clang-tidy",
				".git",
			},
			on_new_config = function(new_config, root_dir)
				-- 优先探测常见的构建目录，让 clangd 能直接吃到生成出的 compile_commands。
				local candidate_dirs = {
					root_dir,
					vim.fs.joinpath(root_dir, "build"),
					vim.fs.joinpath(root_dir, "cmake-build-debug"),
					vim.fs.joinpath(root_dir, "cmake-build-release"),
				}

				for _, dir in ipairs(candidate_dirs) do
					local compile_commands = vim.fs.joinpath(dir, "compile_commands.json")
					if uv.fs_stat(compile_commands) then
						new_config.cmd = vim.deepcopy(new_config.cmd)
						table.insert(new_config.cmd, "--compile-commands-dir=" .. dir)
						break
					end
				end
			end,
		}

		vim.lsp.config["lua_ls"] = {
			settings = {
				Lua = {
					runtime = {
						version = "LuaJIT",
					},
					diagnostics = {
						globals = { "vim" },
					},
					workspace = {
						library = vim.api.nvim_get_runtime_file("", true),
						checkThirdParty = false,
					},
				},
			},
		}

		vim.lsp.config["vtsls"] = {
			root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
			settings = {
				typescript = {
					inlayHints = vim.deepcopy(js_ts_inlay_hints),
				},
				javascript = {
					inlayHints = vim.deepcopy(js_ts_inlay_hints),
				},
			},
		}

		vim.lsp.config["eslint"] = {
			root_markers = {
				"eslint.config.js",
				"eslint.config.mjs",
				"eslint.config.cjs",
				".eslintrc",
				".eslintrc.js",
				".eslintrc.cjs",
				".git",
			},
			settings = {
				workingDirectory = { mode = "auto" },
			},
		}

		vim.lsp.config["tailwindcss"] = {
			root_markers = {
				"tailwind.config.js",
				"tailwind.config.ts",
				"postcss.config.js",
				"postcss.config.cjs",
				"package.json",
				".git",
			},
			filetypes = {
				"css",
				"scss",
				"html",
				"javascript",
				"javascriptreact",
				"typescript",
				"typescriptreact",
			},
		}

		vim.lsp.config["jsonls"] = {
			on_new_config = function(new_config)
				new_config.settings = new_config.settings or {}
				new_config.settings.json = new_config.settings.json or {}
				new_config.settings.json.schemas = get_json_schemas()
			end,
			settings = {
				json = {
					validate = { enable = true },
					format = { enable = false },
				},
			},
		}

		vim.lsp.config["basedpyright"] = {
			root_markers = {
				"pyproject.toml",
				"setup.py",
				"setup.cfg",
				"requirements.txt",
				".git",
			},
			settings = {
				basedpyright = {
					analysis = {
						autoSearchPaths = true,
						typeCheckingMode = "standard",
						useLibraryCodeForTypes = true,
					},
				},
			},
		}

		vim.lsp.config["ruff"] = {
			root_markers = {
				"pyproject.toml",
				"ruff.toml",
				".ruff.toml",
				"setup.cfg",
				".git",
			},
		}

		local function enable_inlay_hints(bufnr)
			local hint = vim.lsp.inlay_hint
			if not (hint and hint.enable) then
				return
			end

			if not pcall(hint.enable, true, bufnr) then
				hint.enable(true, { bufnr = bufnr })
			end
		end

		local function enable_semantic_tokens(client, bufnr)
			local semantic = vim.lsp.semantic_tokens
			if not (semantic and semantic.enable) then
				return
			end

			if not pcall(semantic.enable, true, bufnr) then
				semantic.enable(true, { bufnr = bufnr, client = client })
			end
		end

		local augroup = vim.api.nvim_create_augroup("UserLspCapabilities", { clear = true })
		vim.api.nvim_create_autocmd("LspAttach", {
			group = augroup,
			desc = "按需启用 LSP 功能，避免在不支持的服务器上浪费资源",
			callback = function(event)
				local client = vim.lsp.get_client_by_id(event.data.client_id)
				if not client then
					return
				end

				local bufnr = event.buf

				if client.name == "stylua" then
					-- 防御式兜底：即使 stylua 被外部路径拉起，也立即停掉，避免和预期不一致。
					client:stop()
					return
				end

				local ok_navic, navic = pcall(require, "nvim-navic")
				if ok_navic and client.server_capabilities.documentSymbolProvider then
					-- navic 依赖 documentSymbol，缺这个能力时不强绑，避免无意义 attach。
					navic.attach(client, bufnr)
				end

				if client:supports_method("textDocument/inlayHint") then
					enable_inlay_hints(bufnr)
				end

				if
					client:supports_method("textDocument/semanticTokens/full")
					or client:supports_method("textDocument/semanticTokens/range")
				then
					enable_semantic_tokens(client, bufnr)
				end
			end,
		})

	end,
}
