local map = vim.keymap.set
map("n", "<leader>tt", "<cmd>TestNearest<CR>", { desc = "Test nearest" })
map("n", "<leader>tf", "<cmd>TestFile<CR>", { desc = "Test file" })
map("n", "<leader>tl", "<cmd>TestLast<CR>", { desc = "Test last" })
map("n", "<leader>tx", require("config.plugins.tests").close_runner, { desc = "Close test runner" })
