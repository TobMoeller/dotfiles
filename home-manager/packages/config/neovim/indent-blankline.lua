
vim.api.nvim_set_hl(0, 'IndentScopeHighlight', { fg = '#737475',  bold = false })


require('ibl').setup({
  exclude = {
    filetypes = {
      'help',
      'terminal',
      'dashboard',
      'packer',
      'lspinfo',
      'TelescopePrompt',
      'TelescopeResults',
    },
    buftypes = {
      'terminal',
      'NvimTree',
    },
  },
  indent = {
    char = '▏'
  },
  scope = {
    show_start = false,
    highlight = {
      'IndentScopeHighlight'
    }
  }
})
