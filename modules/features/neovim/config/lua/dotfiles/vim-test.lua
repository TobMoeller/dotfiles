local label = 'tests'
local function in_herdr()
  return vim.env.HERDR_PANE_ID and vim.env.HERDR_PANE_ID ~= ''
end
local function herdr(args)
  local result = vim.system(vim.list_extend({ vim.env.HERDR_BIN_PATH or 'herdr' }, args), { text = true }):wait(3000)
  if result.code ~= 0 then return nil end
  local ok, decoded = pcall(vim.json.decode, result.stdout)
  return ok and decoded.result or nil
end
local function find_runner()
  if not vim.env.HERDR_WORKSPACE_ID or not vim.env.HERDR_TAB_ID then return nil end
  local result = herdr({ 'pane', 'list', '--workspace', vim.env.HERDR_WORKSPACE_ID })
  for _, pane in ipairs(result and result.panes or {}) do
    if pane.label == label and pane.tab_id == vim.env.HERDR_TAB_ID then return pane.pane_id end
  end
end
local function run(command)
  local pane = find_runner()
  if not pane then
    local result = herdr({ 'pane', 'split', '--pane', vim.env.HERDR_PANE_ID,
      '--direction', 'right', '--ratio', '0.5', '--cwd', vim.fn.getcwd(), '--no-focus' })
    pane = result and result.pane and result.pane.pane_id
    if pane then herdr({ 'pane', 'rename', pane, label }) end
  end
  if not pane or not herdr({ 'pane', 'run', pane, command }) then
    vim.notify('vim-test: could not run the command in herdr', vim.log.levels.ERROR)
  end
end
vim.g['test#custom_strategies'] = { herdr = run }
vim.g['test#strategy'] = in_herdr() and 'herdr' or 'neovim'
vim.keymap.set('n', '<leader>tn', '<cmd>TestNearest<CR>', { desc = 'Test nearest' })
vim.keymap.set('n', '<leader>tf', '<cmd>TestFile<CR>', { desc = 'Test file' })
vim.keymap.set('n', '<leader>tl', '<cmd>TestLast<CR>', { desc = 'Test last' })
vim.keymap.set('n', '<leader>tc', function()
  if in_herdr() then
    local pane = find_runner()
    if pane then herdr({ 'pane', 'close', pane }) end
  end
end, { desc = 'Close herdr test runner' })
