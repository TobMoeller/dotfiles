vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.options")
require("config.plugins.editor")
require("config.theme")
for _, plugin in ipairs({
    "treesitter", "telescope", "nvim-tree", "lualine", "bufferline",
    "indent-blankline", "git", "tests", "completion",
}) do
    require("config.plugins." .. plugin)
end
require("config.lsp")
require("config.keymaps")
