local map = vim.keymap.set
map("x", "y", "myy`y", { desc = "Yank and keep cursor position" })
map("x", "Y", "myy`Y", { desc = "Yank lines and keep cursor position" })
map("n", "q:", ":q", { desc = "Correct :q typo" })
map({ "i", "n" }, ";;", "<Esc>A;", { desc = "Append semicolon" })
map({ "i", "n" }, ",,", "<Esc>A,", { desc = "Append comma" })
map("n", "<leader>x", function() vim.ui.open(vim.fn.expand("%:p")) end, { desc = "Open with external application" })

map("i", "<A-j>", "<Esc>:move .+1<CR>==gi", { desc = "Move line down" })
map("i", "<A-k>", "<Esc>:move .-2<CR>==gi", { desc = "Move line up" })
map("n", "<A-j>", ":move .+1<CR>==", { desc = "Move line down" })
map("n", "<A-k>", ":move .-2<CR>==", { desc = "Move line up" })
map("x", "<A-j>", ":move '>+1<CR>gv=gv", { desc = "Move selection down" })
map("x", "<A-k>", ":move '<-2<CR>gv=gv", { desc = "Move selection up" })

map("n", "<leader><space>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("n", "<leader>q", "<cmd>Bdelete<CR>", { desc = "Close buffer, keep window" })
map("n", "gJ", function() require("treesj").join() end, { desc = "Join syntax node" })
map("n", "gS", function() require("treesj").split() end, { desc = "Split syntax node" })
