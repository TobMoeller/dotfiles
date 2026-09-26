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
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>")

vim.opt.rtp:prepend(vim.fn.stdpath("data") .. "/site/lazy.nvim")

require("config.navigation")
require("config.keymaps")

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("lazy").setup({
    {
        "stevearc/oil.nvim",
        lazy = false,
        keys = {
            { "-", "<cmd>Oil<CR>", desc = "Open parent directory" },
            { "<leader>e", "<cmd>Oil<CR>", desc = "Edit directory with Oil" },
        },
        opts = { columns = {}, view_options = { show_hidden = true } },
    },
    {
        "nvim-tree/nvim-tree.lua",
        cmd = { "NvimTreeToggle", "NvimTreeFindFile", "NvimTreeFindFileToggle", "NvimTreeFocus" },
        keys = {
            { "<leader>n", "<cmd>NvimTreeFindFileToggle<CR>", desc = "Toggle project tree" },
        },
        opts = {
            hijack_netrw = false,
            view = { width = 32 },
            renderer = {
                group_empty = true,
                indent_markers = { enable = true },
                icons = { show = { file = false, folder = false, git = false } },
            },
            git = { enable = false },
            diagnostics = { enable = false },
            filesystem_watchers = { enable = false },
        },
    },
    { "catppuccin/nvim", name = "catppuccin", lazy = true },
    { "folke/tokyonight.nvim", lazy = true },
    { "Mofiqul/dracula.nvim", lazy = true },
    { "doums/darcula", lazy = true },
    { "doums/dark.nvim", lazy = true },
    {
        "ibhagwan/fzf-lua",
        cmd = "FzfLua",
        keys = {
            { "<leader>ff", "<cmd>FzfLua files<CR>", desc = "Find project files" },
            { "<leader>fg", "<cmd>FzfLua live_grep<CR>", desc = "Search project text" },
            { "<leader>fb", "<cmd>FzfLua buffers<CR>", desc = "Find open buffer" },
            { "<leader>fh", "<cmd>FzfLua oldfiles<CR>", desc = "Find recent file" },
        },
        opts = {
            files = { hidden = true },
            grep = { hidden = true },
            keymap = {
                fzf = { ["ctrl-j"] = "down", ["ctrl-k"] = "up" },
            },
        },
    },
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
        lazy = false,
        opts = { PATH = "append" },
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
