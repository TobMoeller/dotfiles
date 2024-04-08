require('bufferline').setup({
  options = {
    -- indicator = {
    --   -- icon = ' ',
    --   style = 'underline',
    -- },
    show_close_icon = false,
    tab_size = 0,
    max_name_length = 25,
    offsets = {
      {
        filetype = 'NvimTree',
        text = '  Files',
        highlight = 'StatusLine',
        text_align = 'left',
      },
    },
    -- separator_style = 'slant',
    modified_icon = '',
    custom_areas = {
      left = function()
        return {
          { text = '    ', fg = '#8fff6d' },
        }
      end,
    },
  },
  highlights = require("catppuccin.groups.integrations.bufferline").get(),
})


vim.keymap.set('n', 'mn', ':BufferLineMoveNext<CR>', { silent = true })
vim.keymap.set('n', 'mp', ':BufferLineMovePrev<CR>', { silent = true })
vim.keymap.set('n', '<Leader><Tab>', ':BufferLineCycleNext<CR>', { silent = true })
vim.keymap.set('n', '<Leader><S-Tab>', ':BufferLineCyclePrev<CR>', { silent = true })
vim.keymap.set('n', '<C-N>', ':BufferLineCycleNext<CR>', { silent = true })
vim.keymap.set('n', '<C-P>', ':BufferLineCyclePrev<CR>', { silent = true })

vim.keymap.set('n', '<Leader>^', '<cmd>lua require("bufferline").go_to(1, true)<CR>', { silent = true })
vim.keymap.set('n', '<Leader>$', '<cmd>lua require("bufferline").go_to(-1, true)<CR>', { silent = true })
