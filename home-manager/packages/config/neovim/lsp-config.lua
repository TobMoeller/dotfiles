local capabilities = require('cmp_nvim_lsp').default_capabilities()
local lspconfig = require('lspconfig')

-- PHP
lspconfig.intelephense.setup({ capabilities = capabilities })
-- lspconfig.phpactor.setup({ capabilities = capabilities })

-- Vue, JavaScript, TypeScript
lspconfig.volar.setup({
  capabilities = capabilities,
  -- Enable "Take Over Mode" where volar will provide all JS/TS LSP services
  -- This drastically improves the responsiveness of diagnostic updates on change
  filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
})

-- Python
lspconfig.pyright.setup({ capabilities = capabilities })


-- Tailwind CSS
lspconfig.tailwindcss.setup({ capabilities = capabilities })

-- JSON
-- require('lspconfig').jsonls.setup({
--   capabilities = capabilities,
--   settings = {
--     json = {
--       schemas = require('schemastore').json.schemas(),
--     },
--   },
-- })

-- lua
-- require('lspconfig').lua_ls.setup({
--     capabilities = capabilities,
--     settings = {
--         Lua = {
--             -- runtime = {version = 'LuaJIT', path = vim.split(package.path, ';')},
--             -- completion = {enable = true, callSnippet = "Both"},
--             diagnostics = {
--                 enable = true,
--                 globals = {'vim', 'describe'}
--             }
--         }
--     }
-- })

-- Keymaps
vim.keymap.set('n', '<Leader>d', '<cmd>lua vim.diagnostic.open_float()<CR>')
vim.keymap.set('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>')
vim.keymap.set('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>')
vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>')
vim.keymap.set('n', 'gi', ':Telescope lsp_implementations<CR>')
vim.keymap.set('n', 'gr', ':Telescope lsp_references<CR>')
vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>')
vim.keymap.set('n', '<Leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>')
vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)

-- Diagnostic configuration
vim.diagnostic.config({
  virtual_text = false,
  float = {
    source = true,
  }
})

-- Sign configuration
vim.fn.sign_define('DiagnosticSignError', { text = '', texthl = 'DiagnosticSignError' })
vim.fn.sign_define('DiagnosticSignWarn', { text = '', texthl = 'DiagnosticSignWarn' })
vim.fn.sign_define('DiagnosticSignInfo', { text = '', texthl = 'DiagnosticSignInfo' })
vim.fn.sign_define('DiagnosticSignHint', { text = '', texthl = 'DiagnosticSignHint' })
