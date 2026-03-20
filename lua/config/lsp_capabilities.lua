-- 统一维护 LSP 客户端能力声明。
-- 这份能力表对齐 blink.cmp 对外声明的 completion 能力，但不直接 require blink.cmp。
local M = {}

local completion_capabilities = {
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
}

local semantic_token_capabilities = {
	textDocument = {
		semanticTokens = {
			multilineTokenSupport = true,
		},
	},
}

function M.get()
	return vim.tbl_deep_extend(
		"force",
		vim.lsp.protocol.make_client_capabilities(),
		completion_capabilities,
		semantic_token_capabilities
	)
end

return M
