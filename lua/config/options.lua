-- 基础编辑器行为配置。
-- 这里只放全局 option 和少量初始化动作；autocmd / clipboard / filetype 已拆到独立模块。
-- 行号
-- vim.opt.relativenumber = true
vim.opt.number = true
-- 关闭 Neovim 默认 intro 画面，避免空启动时先闪一下原生欢迎页再切到 dashboard。
vim.opt.shortmess:append("I")

-- 字体
vim.opt.guifont = "Hack Nerd Font Mono Regular 12"

-- 缩进
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.autoindent = true

-- 光标行
vim.opt.cursorline = true

-- 默认新窗口右和下
vim.opt.splitright = true
vim.opt.splitbelow = true

-- 搜索
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- 外观
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.winborder = "rounded"

-- 主题
--vim.cmd[[colorscheme tokyonight-night]]
-- vim.cmd[[colorscheme onedark]]

-- 禁用鼠标
vim.opt.mouse = ""

-- 光标会在第10行触发向上滚动，或者在倒数第10行触发向下滚动
vim.opt.scrolloff = math.min(10, math.floor(vim.o.lines * 0.3)) -- 不超过窗口高度的30%

-- 启用持久化的撤销历史
vim.o.undofile = true

-- 设置 undo 文件的保存目录
local undodir = vim.fn.stdpath("cache") .. "/undo"
vim.opt.undodir = undodir .. "//"

-- 确保 undo 目录存在
vim.fn.mkdir(undodir, "p")

-- 禁用交换文件
vim.opt.swapfile = false

-- 设置文件编码格式
vim.opt.fileencodings = "utf-8,euc-cn,ucs-bom,gb18030,gbk,gb2312,cp936"

vim.opt.wrap = true -- 启用换行
vim.opt.linebreak = true -- 在单词边界换行（避免截断单词）
vim.opt.breakindent = true -- 保持缩进
vim.opt.showbreak = "↪ " -- 折行显示前缀符号（可选）

-- 性能优化
vim.opt.updatetime = 250 -- 更快的 CursorHold 事件
vim.opt.timeoutlen = 300 -- 更快的按键序列超时
vim.opt.lazyredraw = false -- 不延迟重绘（现代终端性能足够）

-- 更好的补全体验
vim.opt.pumheight = 10 -- 限制补全菜单高度
vim.opt.completeopt = "menu,menuone,noselect"

-- 更好的搜索体验
vim.opt.inccommand = "split" -- 实时预览替换效果
