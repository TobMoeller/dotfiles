local function my_on_attach(bufnr)
  local api = require('nvim-tree.api')

  local function opts(desc)
    return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end

  api.config.mappings.default_on_attach(bufnr)


  vim.keymap.set('n', '-', ':NvimTreeResize -30<CR>', opts('Resize -30'))

  vim.keymap.set('n', '+', ':NvimTreeResize +30<CR>', opts('Resize +30'))
end

require('nvim-tree').setup({
  on_attach = my_on_attach,
  hijack_netrw = false,
  git = {
    ignore = false,
  },
  renderer = {
    group_empty = true,
    icons = {
      show = {
        folder_arrow = false,
      },
    },
    indent_markers = {
      enable = true,
    },
  },
})

