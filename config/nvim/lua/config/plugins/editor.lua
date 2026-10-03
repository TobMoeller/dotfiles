vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.tmux_navigator_no_mappings = 1
vim.g.highlightedyank_highlight_duration = 400
vim.g.rooter_manual_only = 1
vim.api.nvim_create_autocmd("VimEnter", {
    group = vim.api.nvim_create_augroup("DotfilesRoot", { clear = true }),
    callback = function() vim.cmd.Rooter() end,
})
require("nvim-autopairs").setup({})
require("treesj").setup({ use_default_keymaps = false })
require("oil").setup({ columns = {}, view_options = { show_hidden = true } })
