vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.scrolloff = 8
vim.opt.undofile = true
vim.keymap.set("n", "<leader><space>", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", "<leader>e", "<cmd>Explore<CR>")
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>")

vim.opt.rtp:prepend(vim.fn.stdpath("data") .. "/site/lazy.nvim")

require("config.navigation")

require("lazy").setup({
    { "catppuccin/nvim", name = "catppuccin", lazy = true },
    { "folke/tokyonight.nvim", lazy = true },
    { "Mofiqul/dracula.nvim", lazy = true },
    { "doums/darcula", lazy = true },
    { "doums/dark.nvim", lazy = true },
    {
        "NeogitOrg/neogit",
        dependencies = { "nvim-lua/plenary.nvim" },
        cmd = "Neogit",
        keys = { { "<leader>g", "<cmd>Neogit<CR>", desc = "Open Neogit" } },
        opts = {
            integrations = { diffview = false, telescope = false, fzf_lua = false, snacks = false },
        },
    },
    {
        "mason-org/mason.nvim",
        cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate", "MasonLog" },
        opts = {},
    },
}, {
    root = vim.fn.stdpath("data") .. "/lazy",
    lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json",
    install = { missing = false }, -- Install explicitly with :Lazy sync.
    checker = { enabled = false },
    rocks = { enabled = false },
    change_detection = { notify = false },
})

require("config.theme")
