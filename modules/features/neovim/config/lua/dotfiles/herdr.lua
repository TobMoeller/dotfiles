for key, direction in pairs({ h = 'left', j = 'down', k = 'up', l = 'right' }) do
  vim.keymap.set('n', '<C-' .. key .. '>', function()
    local previous = vim.api.nvim_get_current_win()
    vim.cmd.wincmd(key)
    if previous ~= vim.api.nvim_get_current_win() then return end
    if vim.env.HERDR_PANE_ID and vim.env.HERDR_PANE_ID ~= '' then
      local bin = vim.env.HERDR_BIN_PATH or 'herdr'
      vim.system({ bin, 'pane', 'focus', '--direction', direction, '--pane', vim.env.HERDR_PANE_ID }, {}, function(result)
        if result.code ~= 0 then
          vim.schedule(function() vim.notify('herdr navigation: ' .. result.stderr, vim.log.levels.WARN) end)
        end
      end)
    end
  end, { silent = true, desc = 'Navigate ' .. direction .. ' (Neovim/herdr)' })
end
