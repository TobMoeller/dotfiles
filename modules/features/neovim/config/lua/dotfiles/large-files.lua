local M = { max_bytes = 1024 * 1024, max_lines = 20000, max_line_length = 4000 }

function M.is_large(bufnr)
  return vim.b[bufnr or 0].dotfiles_large_file == true
end

local function disable_features(bufnr, reason)
  if M.is_large(bufnr) then return end
  vim.b[bufnr].dotfiles_large_file = true
  vim.b[bufnr].dotfiles_large_file_reason = reason
  vim.b[bufnr].sleuth_automatic = 0
  vim.b[bufnr].ibl_disable = true
  vim.bo[bufnr].syntax = 'OFF'
  vim.bo[bufnr].synmaxcol = 200
  pcall(vim.treesitter.stop, bufnr)
  vim.diagnostic.enable(false, { bufnr = bufnr })
  for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
    vim.wo[win].spell = false
    vim.wo[win].foldmethod = 'manual'
  end
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    vim.lsp.buf_detach_client(bufnr, client.id)
  end
  if package.loaded.gitsigns then require('gitsigns').detach(bufnr) end
  if package.loaded.ibl then require('ibl').setup_buffer(bufnr, { enabled = false }) end
  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.notify('Large file: ' .. reason .. '. Highlighting, LSP and automatic completion disabled.', vim.log.levels.INFO)
    end
  end)
end

function M.check(bufnr, scan_lines)
  if M.is_large(bufnr) or vim.bo[bufnr].buftype ~= '' then return end
  local count = vim.api.nvim_buf_line_count(bufnr)
  if count >= M.max_lines then
    return disable_features(bufnr, 'at least ' .. M.max_lines .. ' lines')
  end
  if vim.api.nvim_buf_get_offset(bufnr, count) >= M.max_bytes then
    return disable_features(bufnr, 'at least 1 MiB')
  end
  if scan_lines and not vim.b[bufnr].dotfiles_size_checked then
    vim.b[bufnr].dotfiles_size_checked = true
    for start = 0, count - 1, 256 do
      for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, start, math.min(start + 256, count), false)) do
        if #line >= M.max_line_length then
          return disable_features(bufnr, 'line of at least ' .. M.max_line_length .. ' bytes')
        end
      end
    end
  elseif not scan_lines then
    -- During editing, inspect only the current line, not the whole document.
    if bufnr == vim.api.nvim_get_current_buf() and #vim.api.nvim_get_current_line() >= M.max_line_length then
      return disable_features(bufnr, 'long line')
    end
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup('DotfilesLargeFiles', { clear = true })
  vim.api.nvim_create_autocmd('BufReadPre', {
    group = group,
    callback = function(args)
      local stat = vim.uv.fs_stat(args.file)
      if stat and stat.size >= M.max_bytes then disable_features(args.buf, 'at least 1 MiB') end
    end,
  })
  vim.api.nvim_create_autocmd('BufReadPost', {
    group = group,
    callback = function(args) M.check(args.buf, true) end,
  })
  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
    group = group,
    callback = function(args) M.check(args.buf, false) end,
  })
  vim.api.nvim_create_autocmd('BufWinEnter', {
    group = group,
    callback = function(args)
      if M.is_large(args.buf) then
        vim.wo.spell = false
        vim.wo.foldmethod = 'manual'
      end
    end,
  })
end

return M
