-- Parsers and matching queries are supplied by Nix; never download them here.
vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("DotfilesTreesitter", { clear = true }),
    callback = function(event)
        local lang = vim.treesitter.language.get_lang(vim.bo[event.buf].filetype)
        if vim.bo[event.buf].buftype == "" and lang and vim.treesitter.language.add(lang) then
            vim.treesitter.start(event.buf, lang)
        end
    end,
})
require("nvim-treesitter-textobjects").setup({ select = { lookahead = true } })
require("ts_context_commentstring").setup({})
require("config.keymaps.treesitter")
