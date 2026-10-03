vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.wildmode = 'longest:full,full'
vim.opt.completeopt = 'menu,menuone,noselect'

vim.opt.title = true
vim.opt.mouse = 'a' -- all mode

vim.opt.spell = true

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.list = true
vim.opt.listchars = { tab = '▸ ', trail = '·' }

vim.opt.fillchars:append({ eob = ' ' }) -- remove ~ from empty files

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

vim.opt.clipboard = 'unnamedplus' -- system clipboard

vim.opt.confirm = true

vim.opt.signcolumn = 'yes:2'

vim.opt.undofile = true -- stores the undo history for each file
vim.opt.backup = true -- automatically save a backup for each file
vim.opt.backupdir:remove('.') -- Keep backups in Neovim's XDG state directory.

