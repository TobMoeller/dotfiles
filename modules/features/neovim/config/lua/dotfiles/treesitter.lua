local large = require('dotfiles.large-files')
-- Parsers/queries are installed by Nix. No downloads or compilers at startup.
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('DotfilesTreesitter', { clear = true }),
  callback = function(args)
    large.check(args.buf, true)
    if large.is_large(args.buf) then
      pcall(vim.treesitter.stop, args.buf)
      vim.bo[args.buf].syntax = 'OFF'
      -- Built-in ftplugins may start highlighting later in this same event.
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(args.buf) then
          pcall(vim.treesitter.stop, args.buf)
          vim.bo[args.buf].syntax = 'OFF'
        end
      end)
      return
    end
    if vim.bo[args.buf].buftype ~= '' then return end
    if pcall(vim.treesitter.start, args.buf) then
      -- Do not run Vim regex highlighting alongside Treesitter.
      vim.bo[args.buf].syntax = ''
    end
  end,
})

require('nvim-treesitter-textobjects').setup({ select = { lookahead = true } })
for key, capture in pairs({ ['if'] = '@function.inner', af = '@function.outer', ia = '@parameter.inner', aa = '@parameter.outer' }) do
  vim.keymap.set({ 'x', 'o' }, key, function()
    if not large.is_large(0) then
      require('nvim-treesitter-textobjects.select').select_textobject(capture, 'textobjects')
    end
  end, { desc = capture })
end

-- Incremental selection was removed from the new Treesitter plugin API.
-- Keep the familiar v<Enter>, Tab and Shift-Tab using Neovim's node API.
local selections = {}
local function select_node(node)
  local sr, sc, er, ec = node:range()
  if ec == 0 and er > sr then
    er = er - 1
    ec = #vim.api.nvim_buf_get_lines(0, er, er + 1, false)[1]
  end
  if vim.fn.mode():match('[vV\22]') then vim.cmd.normal({ vim.keycode('<Esc>'), bang = true }) end
  vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
  vim.cmd.normal({ 'v', bang = true })
  vim.api.nvim_win_set_cursor(0, { er + 1, math.max(0, ec - 1) })
end
local function expand(initial)
  if large.is_large(0) then return end
  local parsed = pcall(function() vim.treesitter.get_parser():parse() end)
  if not parsed then return end
  local ok, node = pcall(vim.treesitter.get_node)
  if not ok or not node then return end
  local buf = vim.api.nvim_get_current_buf()
  if initial or not selections[buf] then selections[buf] = { node } end
  local stack = selections[buf]
  if not initial then
    local parent = stack[#stack]:parent()
    if parent then stack[#stack + 1] = parent end
  end
  select_node(stack[#stack])
end
vim.keymap.set('n', 'v<CR>', function() expand(true) end, { desc = 'Select syntax node' })
vim.keymap.set('x', 'v<CR>', function() expand(false) end, { desc = 'Expand syntax selection' })
vim.keymap.set('x', '<Tab>', function() expand(false) end, { desc = 'Expand syntax selection' })
vim.keymap.set('x', '<S-Tab>', function()
  local stack = selections[vim.api.nvim_get_current_buf()]
  if stack and #stack > 1 then table.remove(stack); select_node(stack[#stack]) end
end, { desc = 'Shrink syntax selection' })
vim.api.nvim_create_autocmd({ 'BufDelete', 'TextChanged', 'TextChangedI' }, {
  callback = function(args) selections[args.buf] = nil end,
})
