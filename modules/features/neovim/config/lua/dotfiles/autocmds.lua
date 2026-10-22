local group = vim.api.nvim_create_augroup('DotfilesEditor', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  group = group,
  callback = function() vim.hl.on_yank({ timeout = 400 }) end,
})
vim.api.nvim_create_autocmd('BufReadPost', {
  group = group,
  callback = function(args)
    if vim.bo[args.buf].buftype ~= '' then return end
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})
-- Preserve the old Rooter behaviour: choose a root once, without changing it
-- on every buffer switch. herdr/devShell already start us in the project.
vim.api.nvim_create_autocmd('VimEnter', {
  group = group,
  once = true,
  callback = function()
    local start = vim.api.nvim_buf_get_name(0)
    if start == '' then start = vim.fn.getcwd() end
    local root = vim.fs.root(start, { '.git', 'composer.json', 'package.json', 'pyproject.toml', 'flake.nix' })
    if root then vim.api.nvim_set_current_dir(root) end
  end,
})
