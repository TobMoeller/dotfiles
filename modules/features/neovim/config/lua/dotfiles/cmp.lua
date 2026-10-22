local cmp = require('cmp')
local luasnip = require('luasnip')
require('luasnip.loaders.from_vscode').lazy_load()

local function has_words_before()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  return col > 0 and vim.api.nvim_get_current_line():sub(col, col):match('%s') == nil
end

cmp.setup({
  enabled = function()
    return not vim.b.dotfiles_large_file and vim.bo.buftype ~= 'prompt'
  end,
  snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
  formatting = { format = require('lspkind').cmp_format() },
  mapping = {
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_next_item()
      elseif luasnip.locally_jumpable(1) or luasnip.expandable() then luasnip.expand_or_jump()
      elseif has_words_before() then cmp.complete()
      else fallback() end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_prev_item()
      elseif luasnip.locally_jumpable(-1) then luasnip.jump(-1)
      else fallback() end
    end, { 'i', 's' }),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'nvim_lsp_signature_help' },
    { name = 'luasnip' },
    { name = 'path' },
    {
      name = 'buffer',
      keyword_length = 3,
      option = {
        -- Never scan every loaded buffer, or a large log in another window.
        get_bufnrs = function()
          local buf = vim.api.nvim_get_current_buf()
          local bytes = vim.api.nvim_buf_get_offset(buf, vim.api.nvim_buf_line_count(buf))
          return not vim.b[buf].dotfiles_large_file and bytes < 256 * 1024 and { buf } or {}
        end,
      },
    },
  },
  performance = { debounce = 80, throttle = 40, max_view_entries = 50 },
  experimental = { ghost_text = true },
})
