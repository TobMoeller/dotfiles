vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require('dotfiles.options')
require('dotfiles.large-files').setup()
require('dotfiles.keymaps')
require('dotfiles.autocmds')
require('dotfiles.appearance')
require('dotfiles.treesitter')
require('dotfiles.cmp')
require('dotfiles.lsp')
require('dotfiles.telescope')
require('dotfiles.nvim-tree')
require('dotfiles.gitsigns')
require('dotfiles.indent-blankline')
require('dotfiles.lualine')
require('dotfiles.bufferline')
require('dotfiles.herdr')
require('dotfiles.vim-test')

require('nvim-autopairs').setup({
  enabled = function(bufnr) return not vim.b[bufnr].dotfiles_large_file end,
})
vim.keymap.set('n', '<leader>q', '<cmd>Bdelete<CR>', { desc = 'Close buffer, keep layout' })
vim.keymap.set('n', '<leader>g', function()
  require('neogit').open()
end, { desc = 'Git status' })
for key, action in pairs({ gJ = 'join', gS = 'split' }) do
  vim.keymap.set('n', key, function()
    if vim.b.dotfiles_large_file then return end
    local treesj = require('treesj')
    if not vim.g.dotfiles_treesj_setup then
      treesj.setup({ use_default_keymaps = false })
      vim.g.dotfiles_treesj_setup = true
    end
    treesj[action]()
  end, { desc = 'Syntax-aware ' .. action })
end
