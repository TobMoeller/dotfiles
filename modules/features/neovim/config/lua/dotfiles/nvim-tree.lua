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
  git = {
    timeout = 500,
  },
  filters = {
    git_ignored = false,
  },
  filesystem_watchers = {
    ignore_dirs = { '/node_modules', '/vendor', '/.direnv', '/target', '/build', '/.zig-cache' },
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

vim.keymap.set('n', '<Leader>n', ':NvimTreeFindFileToggle<CR>')
