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

		-- Mirrors blink.cmp's advertised completion capabilities without forcing
		-- the full completion plugin to load during ordinary file opens.
		local capabilities = vim.tbl_deep_extend("force", vim.lsp.protocol.make_client_capabilities(), {
			textDocument = {
				completion = {
					completionItem = {
						snippetSupport = true,
						commitCharactersSupport = false,
						documentationFormat = { "markdown", "plaintext" },
						deprecatedSupport = true,
						preselectSupport = false,
						tagSupport = { valueSet = { 1 } },
						insertReplaceSupport = true,
						resolveSupport = {
							properties = {
								"documentation",
								"detail",
								"additionalTextEdits",
								"command",
								"data",
							},
						},
						insertTextModeSupport = {
							valueSet = { 1 },
						},
						labelDetailsSupport = true,
					},
					completionList = {
						itemDefaults = {
							"commitCharacters",
							"editRange",
							"insertTextFormat",
							"insertTextMode",
							"data",
						},
					},
					contextSupport = true,
					insertTextMode = 1,
				},
			},
		}, {
			textDocument = {
				semanticTokens = {
					multilineTokenSupport = true,
				},
			},
		})

		vim.lsp.config("*", {
			capabilities = capabilities,
		})

		local stylua_cfg = vim.lsp.config["stylua"]
		if stylua_cfg then
			stylua_cfg.autostart = false
			stylua_cfg.cmd = nil
		end

		local uv = vim.uv or vim.loop
		local json_schemas

		local function get_json_schemas()
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
					inlayHints = {
						parameterNames = { enabled = "literals" },
						parameterTypes = { enabled = true },
						variableTypes = { enabled = true },
						propertyDeclarationTypes = { enabled = true },
						functionLikeReturnTypes = { enabled = true },
						enumMemberValues = { enabled = true },
					},
				},
				javascript = {
					inlayHints = {
						parameterNames = { enabled = "literals" },
						parameterTypes = { enabled = true },
						variableTypes = { enabled = true },
						propertyDeclarationTypes = { enabled = true },
						functionLikeReturnTypes = { enabled = true },
						enumMemberValues = { enabled = true },
					},
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
					client:stop()
					return
				end

				local ok_navic, navic = pcall(require, "nvim-navic")
				if ok_navic and client.server_capabilities.documentSymbolProvider then
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
