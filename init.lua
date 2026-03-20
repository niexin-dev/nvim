-- 配置 Neovim 基础选项
require("config.options")
-- 配置跨环境剪贴板桥接
require("config.clipboard")
-- 配置 filetype 识别与缩进策略
require("config.filetypes")
-- 配置通用自动命令
require("config.autocmds")
-- 配置全局诊断展示策略
require("config.diagnostics")
-- 配置 Neovim 快捷键
require("config.keymaps")
-- 配置 lazy.nvim，通过 lazy.nvim 来加载插件
require("config.lazy")
