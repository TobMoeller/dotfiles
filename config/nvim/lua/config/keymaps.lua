for _, group in ipairs({ "navigation", "multiplexer", "editing", "bufferline", "telescope", "nvim-tree", "lsp", "tests" }) do
    require("config.keymaps." .. group)
end
vim.keymap.set("n", "-", "<cmd>Oil<CR>", { desc = "Open parent directory" })
vim.keymap.set("n", "<leader>e", "<cmd>Oil<CR>", { desc = "Edit directory with Oil" })
vim.keymap.set("n", "<leader>ut", "<cmd>Theme<CR>", { desc = "Choose theme" })
vim.keymap.set("n", "<leader>g", "<cmd>Neogit<CR>", { desc = "Open Neogit" })
