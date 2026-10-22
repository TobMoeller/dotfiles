vim.opt.termguicolors = true
require('catppuccin').setup({
  flavour = 'mocha',
  integrations = { cmp = true, nvimtree = true, telescope = { enabled = true } },
})
vim.cmd.colorscheme('catppuccin-mocha')
