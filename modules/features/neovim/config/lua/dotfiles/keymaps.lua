local map = vim.keymap.set
map('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true })
map('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true })
map('v', '<', '<gv')
map('v', '>', '>gv')
map('v', 'y', 'myy`y')
map('v', 'Y', 'myy`Y')
map('n', 'q:', ':q')
map('v', 'p', '"_dP')
map({ 'i', 'n' }, ';;', '<Esc>A;')
map({ 'i', 'n' }, ',,', '<Esc>A,')
map('n', '<leader>x', function() vim.ui.open(vim.fn.expand('%:p')) end, { desc = 'Open with default application' })
map('n', '<Esc>', '<cmd>nohlsearch<CR>')
map('t', '<Esc>', '<C-\\><C-N>')

local down, up = '<A-j>', '<A-k>'
if vim.uv.os_uname().sysname == 'Darwin' then down, up = '<º>', '<∆>' end
map('i', down, '<Esc>:move .+1<CR>==gi')
map('i', up, '<Esc>:move .-2<CR>==gi')
map('n', down, ':move .+1<CR>==')
map('n', up, ':move .-2<CR>==')
map('x', down, ":move '>+1<CR>gv-gv")
map('x', up, ":move '<-2<CR>gv-gv")
