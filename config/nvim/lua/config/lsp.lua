require("mason").setup({ PATH = "append" })
vim.lsp.config("*", { capabilities = require("cmp_nvim_lsp").default_capabilities() })
vim.lsp.config("ts_ls", {
    filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact" },
})

-- Servers can come from the project DevShell, Nix, or Mason (in that order).
-- Enable only installed servers; installing a Mason package also refreshes this list.
local servers = { "intelephense", "dartls", "sourcekit", "ts_ls", "pyright", "tailwindcss", "zls", "gopls" }
local function enable_available()
    for _, name in ipairs(servers) do
        local config = vim.lsp.config[name]
        if config and type(config.cmd) == "table" and vim.fn.executable(config.cmd[1]) == 1 then
            vim.lsp.enable(name)
        end
    end
end
enable_available()
require("mason-registry"):on("package:install:success", vim.schedule_wrap(enable_available))

vim.diagnostic.config({
    virtual_text = false,
    float = { source = true },
    signs = { text = {
        [vim.diagnostic.severity.ERROR] = "",
        [vim.diagnostic.severity.WARN] = "",
        [vim.diagnostic.severity.INFO] = "",
        [vim.diagnostic.severity.HINT] = "",
    } },
})
