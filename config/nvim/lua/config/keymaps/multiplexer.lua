local directions = { h = "left", j = "down", k = "up", l = "right" }

for key, direction in pairs(directions) do
    vim.keymap.set("n", "<C-" .. key .. ">", function()
        local window = vim.api.nvim_get_current_win()
        vim.cmd.wincmd(key)
        if window ~= vim.api.nvim_get_current_win() then return end

        if vim.env.HERDR_PANE_ID and vim.env.HERDR_PANE_ID ~= "" then
            local herdr = vim.env.HERDR_BIN_PATH or "herdr"
            vim.fn.system({ herdr, "pane", "focus", "--direction", direction, "--current" })
        elseif vim.env.TMUX and vim.env.TMUX ~= "" then
            local commands = { left = "Left", down = "Down", up = "Up", right = "Right" }
            vim.cmd("TmuxNavigate" .. commands[direction])
        end
    end, { desc = "Navigate " .. direction .. " (Neovim/Herdr)" })
end
