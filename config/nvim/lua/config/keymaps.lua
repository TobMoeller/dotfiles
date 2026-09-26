local map = vim.keymap.set

map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, desc = "Down display line" })
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, desc = "Up display line" })
map("x", "<", "<gv", { desc = "Indent left and keep selection" })
map("x", ">", ">gv", { desc = "Indent right and keep selection" })
map("x", "p", '"_dP', { desc = "Replace selection without overwriting register" })

map("n", "<leader>bn", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bp", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "<C-n>", "<cmd>tabnext<CR>", { desc = "Next tab" })
map("n", "<C-p>", "<cmd>tabprevious<CR>", { desc = "Previous tab" })
map("n", "<leader>tn", "<cmd>tabnew<CR>", { desc = "New tab" })
map("n", "<leader>tc", "<cmd>tabclose<CR>", { desc = "Close tab" })
map("n", "<leader>sv", "<cmd>vsplit<CR>", { desc = "Vertical split" })
map("n", "<leader>sh", "<cmd>split<CR>", { desc = "Horizontal split" })
map("n", "<leader>se", "<C-w>=", { desc = "Equal split sizes" })
