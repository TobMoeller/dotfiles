----------
-- OPTIONS
----------

vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.wildmode = 'longest:full,full'
vim.opt.completeopt = 'menuone,longest,preview'

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
vim.opt.backupdir:remove('.') -- dont store backups inside the current directory -> next option is hidden file in /home

----------
-- KEYMAPS
----------

-- leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- move line by line inside of wrapped text, except when a number is supplied
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true })

-- reselect after indenting
vim.keymap.set('v', '<', '<gv')
vim.keymap.set('v', '>', '>gv')

-- maintain cursor position when yanking
vim.keymap.set('v', 'y', 'myy`y')
vim.keymap.set('v', 'Y', 'myy`Y')

-- fix :q typos
vim.keymap.set('n', 'q:', ':q')

-- fix pasting into visually selected stuff
vim.keymap.set('v', 'p', '"_dP')

vim.keymap.set({'i', 'n'}, ';;', '<Esc>A;')
vim.keymap.set({'i', 'n'}, ',,', '<Esc>A,')

-- remove search highlighting
vim.keymap.set('n', '<Leader>k', ':nohlsearch<CR>')

-- open file with default os program
vim.keymap.set('n', '<Leader>x', ':!xdg-open %<CR><CR>')

-- move lines with alt
if (vim.loop.os_uname().sysname == "Darwin")
  then
    vim.keymap.set('i', '<º>', '<Esc>:move .+1<CR>==gi')
    vim.keymap.set('i', '<∆>', '<Esc>:move .-2<CR>==gi')
    vim.keymap.set('n', '<º>', '<Esc>:move .+1<CR>==')
    vim.keymap.set('n', '<∆>', '<Esc>:move .-2<CR>==')
    vim.keymap.set('x', '<º>', ":move '>+1<CR>gv-gv")
    vim.keymap.set('x', '<∆>', ":move '<-2<CR>gv-gv")
  else
    vim.keymap.set('i', '<A-j>', '<Esc>:move .+1<CR>==gi')
    vim.keymap.set('i', '<A-k>', '<Esc>:move .-2<CR>==gi')
    vim.keymap.set('n', '<A-j>', '<Esc>:move .+1<CR>==')
    vim.keymap.set('n', '<A-k>', '<Esc>:move .-2<CR>==')
    vim.keymap.set('x', '<A-j>', ":move '>+1<CR>gv-gv")
    vim.keymap.set('x', '<A-k>', ":move '<-2<CR>gv-gv")
end

-- tab/buffer navigation
-- vim.keymap.set('n', '<Leader><Tab>', vim.cmd.bn)
-- vim.keymap.set('n', '<Leader><S-Tab>', vim.cmd.bp)

-- exit terminal mode
vim.keymap.set('t', '<ESC>', '<C-\\><C-N>')
