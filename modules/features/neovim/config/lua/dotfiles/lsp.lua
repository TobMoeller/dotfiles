local large = require('dotfiles.large-files')
vim.filetype.add({ pattern = { ['.*%.blade%.php'] = 'blade' } })

vim.lsp.config('*', {
  capabilities = require('cmp_nvim_lsp').default_capabilities(),
  flags = { debounce_text_changes = 200 },
})

vim.lsp.config('ts_ls', {
  filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact' },
})
vim.lsp.config('lua_ls', {
  settings = { Lua = { diagnostics = { globals = { 'vim' } }, telemetry = { enable = false } } },
})
vim.lsp.config('intelephense', {
  init_options = {
    storagePath = vim.fn.stdpath('cache') .. '/intelephense',
    globalStoragePath = vim.fn.stdpath('state') .. '/intelephense',
  },
  settings = { intelephense = { files = { maxSize = large.max_bytes } } },
})
vim.lsp.config('laravel_lsp', {
  cmd = { 'laravel-lsp' },
  filetypes = { 'php', 'blade' },
  root_dir = function(bufnr, on_dir)
    large.check(bufnr, true)
    if large.is_large(bufnr) then return end
    local root = vim.fs.root(bufnr, 'artisan')
    if root then on_dir(root) end
  end,
  -- Keep project files unchanged merely by opening them in the editor.
  init_options = { pestGenerateDocBlocks = false },
})

-- Don't start servers in huge/minified files or when their runtime is absent.
-- Optional Dart/Swift/Zig servers come from their project's devShell/SDK.
for name, executable in pairs({
  intelephense = 'intelephense', laravel_lsp = 'laravel-lsp',
  ts_ls = 'typescript-language-server', tailwindcss = 'tailwindcss-language-server',
  pyright = 'pyright-langserver', lua_ls = 'lua-language-server', nil_ls = 'nil',
  dartls = 'dart', sourcekit = 'sourcekit-lsp', zls = 'zls',
}) do
  if name ~= 'laravel_lsp' then
    local root_dir = vim.lsp.config[name].root_dir
    vim.lsp.config(name, {
      root_dir = function(bufnr, on_dir)
        large.check(bufnr, true)
        if large.is_large(bufnr) then return end
        if root_dir then return root_dir(bufnr, on_dir) end
        local root = vim.fs.root(bufnr, vim.lsp.config[name].root_markers or { '.git' })
        on_dir(root or vim.fn.getcwd())
      end,
    })
  end
  if vim.fn.executable(executable) == 1 then vim.lsp.enable(name) end
end

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('DotfilesLsp', { clear = true }),
  callback = function(args)
    if large.is_large(args.buf) then
      vim.lsp.buf_detach_client(args.buf, args.data.client_id)
    end
  end,
})

local map = vim.keymap.set
map('n', '<leader>d', vim.diagnostic.open_float, { desc = 'Diagnostics' })
map('n', '[d', function() vim.diagnostic.jump({ count = -1, float = true }) end)
map('n', ']d', function() vim.diagnostic.jump({ count = 1, float = true }) end)
map('n', 'gd', '<cmd>Telescope lsp_definitions<CR>')
map('n', 'gi', '<cmd>Telescope lsp_implementations<CR>')
map('n', 'gr', '<cmd>Telescope lsp_references<CR>')
map('n', 'K', vim.lsp.buf.hover)
map('n', '<leader>rn', vim.lsp.buf.rename)
map({ 'n', 'x' }, '<leader>ca', vim.lsp.buf.code_action)

vim.diagnostic.config({
  virtual_text = false,
  float = { source = true },
  signs = { text = {
    [vim.diagnostic.severity.ERROR] = '',
    [vim.diagnostic.severity.WARN] = '',
    [vim.diagnostic.severity.INFO] = '',
    [vim.diagnostic.severity.HINT] = '',
  } },
})
