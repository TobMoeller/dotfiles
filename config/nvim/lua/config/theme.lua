local themes = {
    "catppuccin-mocha", "catppuccin-macchiato", "catppuccin-frappe", "catppuccin-latte",
    "tokyonight-night", "tokyonight-storm", "tokyonight-moon", "tokyonight-day",
    "dracula", "darcula", "dark", "default",
}
local preference = vim.fn.stdpath("state") .. "/colorscheme"

local function apply(name, save)
    local ok, err = pcall(vim.cmd.colorscheme, name)
    if not ok then
        vim.notify(tostring(err) .. " (install themes with :Lazy sync)", vim.log.levels.WARN)
        return
    end
    if save then
        vim.fn.mkdir(vim.fn.stdpath("state"), "p")
        vim.fn.writefile({ name }, preference)
    end
end

vim.api.nvim_create_user_command("Theme", function(args)
    if args.args ~= "" then
        apply(args.args, true)
    else
        vim.ui.select(themes, { prompt = "Colorscheme:" }, function(name)
            if name then apply(name, true) end
        end)
    end
end, { nargs = "?", complete = function() return themes end })
vim.keymap.set("n", "<leader>ut", "<cmd>Theme<CR>", { desc = "Choose theme" })
vim.opt.termguicolors = true

local selected = "catppuccin-mocha"
if vim.fn.filereadable(preference) == 1 then
    selected = vim.fn.readfile(preference)[1] or selected
end
-- Keep first startup usable before the theme plugins have been installed.
pcall(vim.cmd.colorscheme, selected)
