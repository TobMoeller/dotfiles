require('nvim-treesitter.configs').setup({
  -- ensure_installed = 'all',
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = true,
  },
  textobjects = {
    select = {
      enable = true,
      lookahead = true,
      keymaps = {
        ['if'] = '@function.inner',
        ['af'] = '@function.outer',
        ['ia'] = '@parameter.inner',
        ['aa'] = '@parameter.outer',
      },
    }
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = 'v<CR>',
      scope_incremental = 'v<CR>',
      node_incremental = '<TAB>',
      node_decremental = '<S-TAB>',
    },
  },
})
