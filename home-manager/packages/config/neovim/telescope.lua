local actions = require('telescope.actions')
local lga_actions = require("telescope-live-grep-args.actions")

vim.cmd([[
  highlight link TelescopePromptTitle PMenuSel
  highlight link TelescopePreviewTitle PMenuSel
  highlight link TelescopePromptNormal NormalFloat
  highlight link TelescopePromptBorder FloatBorder
  highlight link TelescopeNormal CursorLine
  highlight link TelescopeBorder CursorLineBg
]])

require('telescope').setup({
  defaults = {
    path_display = { truncate = 1 },
    prompt_prefix = '   ',
    selection_caret = '  ',
    layout_config = {
      prompt_position = 'top',
    },
    sorting_strategy = 'ascending',
    mappings = {
      i = {
        ['<esc>'] = actions.close,
        ['<C-Down>'] = actions.cycle_history_next,
        ['<C-Up>'] = actions.cycle_history_prev,
        -- ["<C-k>"] = lga_actions.quote_prompt(),
        -- ["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
        ["<C-p>"] = lga_actions.quote_prompt(),
        ["<C-n>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
        -- ["<C-h>"] = "which_key",
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,
        ["<C-h>"] = actions.preview_scrolling_left,
        ["<C-l>"] = actions.preview_scrolling_right,
      },
    },
    file_ignore_patterns = { '.git/' },
  },
  pickers = {
    find_files = {
      hidden = true,
    },
    -- buffers = {
    --   previewer = false,
    --   layout_config = {
    --     width = 80,
    --   },
    -- },
    oldfiles = {
      prompt_title = 'History',
    },
    -- lsp_references = {
    --   previewer = false,
    -- },
  },
})

require('telescope').load_extension('fzf')
require('telescope').load_extension('live_grep_args')

vim.keymap.set('n', '<leader>ff', [[<cmd>lua require('telescope.builtin').find_files()<CR>]])
vim.keymap.set('n', '<leader>fF', [[<cmd>lua require('telescope.builtin').find_files({ no_ignore = true, prompt_title = 'All Files' })<CR>]])
vim.keymap.set('n', '<leader>fb', [[<cmd>lua require('telescope.builtin').buffers()<CR>]])
vim.keymap.set('n', '<leader>fg', [[<cmd>lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>]])
vim.keymap.set('v', '<leader>fg', require("telescope-live-grep-args.shortcuts").grep_word_under_cursor)
vim.keymap.set('n', '<leader>fh', [[<cmd>lua require('telescope.builtin').oldfiles()<CR>]])
vim.keymap.set('n', '<leader>fs', [[<cmd>lua require('telescope.builtin').lsp_document_symbols()<CR>]])
