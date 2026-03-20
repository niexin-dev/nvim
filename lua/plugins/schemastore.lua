-- SchemaStore 只作为懒依赖存在。
-- 实际什么时候 require，由 nvim-lspconfig 里的 jsonls 配置决定。
return {
	"b0o/SchemaStore.nvim",
	lazy = true,
}
