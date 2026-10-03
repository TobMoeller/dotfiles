for key, query in pairs({ ["if"] = "@function.inner", af = "@function.outer", ia = "@parameter.inner", aa = "@parameter.outer" }) do
    vim.keymap.set({ "x", "o" }, key, function()
        require("nvim-treesitter-textobjects.select").select_textobject(query, "textobjects")
    end, { desc = "Select " .. query })
end

local selections = {}
local function select_node(node)
    if not node then return end
    local first_row, first_col, last_row, last_col = node:range()
    if last_col == 0 and last_row > first_row then
        last_row = last_row - 1
        last_col = #vim.api.nvim_buf_get_lines(0, last_row, last_row + 1, true)[1]
    end
    vim.cmd.normal({ "\27", bang = true })
    vim.api.nvim_win_set_cursor(0, { first_row + 1, first_col })
    vim.cmd.normal({ "v", bang = true })
    vim.api.nvim_win_set_cursor(0, { last_row + 1, math.max(last_col - 1, 0) })
end

vim.keymap.set("n", "v<CR>", function()
    local node = vim.treesitter.get_node()
    selections[vim.api.nvim_get_current_buf()] = node and { node } or {}
    select_node(node)
end, { desc = "Select syntax node" })

local function grow()
    local history = selections[vim.api.nvim_get_current_buf()]
    if not history or #history == 0 then return end
    local parent = history[#history]:parent()
    if parent then
        history[#history + 1] = parent
        select_node(parent)
    end
end
vim.keymap.set("x", "<Tab>", grow, { desc = "Expand syntax selection" })
vim.keymap.set("x", "v<CR>", grow, { desc = "Expand syntax selection" })
vim.keymap.set("x", "<S-Tab>", function()
    local history = selections[vim.api.nvim_get_current_buf()]
    if history and #history > 1 then
        table.remove(history)
        select_node(history[#history])
    end
end, { desc = "Shrink syntax selection" })
