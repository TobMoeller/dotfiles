-- vim-test: run the test command in a split of the surrounding multiplexer.
--
--   herdr (HERDR_PANE_ID) -> a dedicated runner pane driven via the herdr CLI
--   tmux  (TMUX)          -> vimux
--   neither               -> vim-test's built-in :terminal split
--
-- The herdr runner is looked up by its pane label, so a restarted Neovim reuses
-- the pane that is already open instead of splitting the tab again.

local RUNNER_LABEL = 'tests'

local function in_herdr()
    return vim.env.HERDR_PANE_ID ~= nil and vim.env.HERDR_PANE_ID ~= ''
end

local function in_tmux()
    return vim.env.TMUX ~= nil and vim.env.TMUX ~= ''
end

-- run a herdr CLI command, return its decoded `result` (nil on any failure)
local function herdr(args)
    local bin = vim.env.HERDR_BIN_PATH
    if bin == nil or bin == '' then bin = 'herdr' end

    local out = vim.fn.system(vim.list_extend({ bin }, args))
    if vim.v.shell_error ~= 0 then return nil end

    local ok, decoded = pcall(vim.json.decode, out)
    if not ok or type(decoded) ~= 'table' then return nil end

    return decoded.result
end

local function find_runner()
    local result = herdr({ 'pane', 'list', '--workspace', vim.env.HERDR_WORKSPACE_ID })
    for _, pane in ipairs(result and result.panes or {}) do
        if pane.label == RUNNER_LABEL and pane.tab_id == vim.env.HERDR_TAB_ID then
            return pane.pane_id
        end
    end
end

local function ensure_runner()
    local pane = find_runner()
    if pane then return pane end

    local result = herdr({
        'pane', 'split', '--pane', vim.env.HERDR_PANE_ID,
        '--direction', 'right', '--ratio', '0.5',
        '--cwd', vim.fn.getcwd(), '--no-focus',
    })
    pane = result and result.pane and result.pane.pane_id
    if pane then
        herdr({ 'pane', 'rename', pane, RUNNER_LABEL })
    end

    return pane
end

local function run_in_herdr(cmd)
    local pane = ensure_runner()
    if not pane then
        vim.notify('vim-test: could not open a herdr runner pane', vim.log.levels.ERROR)
        return
    end

    herdr({ 'pane', 'run', pane, cmd })
end

local function close_runner()
    if in_herdr() then
        local pane = find_runner()
        if pane then herdr({ 'pane', 'close', pane }) end
    elseif in_tmux() then
        vim.fn.VimuxCloseRunner()
    end
end

vim.g['test#custom_strategies'] = { herdr = run_in_herdr }

if in_herdr() then
    vim.g['test#strategy'] = 'herdr'
elseif in_tmux() then
    vim.g['test#strategy'] = 'vimux'
else
    vim.g['test#strategy'] = 'neovim'
end

vim.keymap.set('n', '<Leader>tn', ':TestNearest<CR>', { desc = 'Test nearest' })
vim.keymap.set('n', '<Leader>tf', ':TestFile<CR>', { desc = 'Test file' })
vim.keymap.set('n', '<Leader>tl', ':TestLast<CR>', { desc = 'Test last' })
vim.keymap.set('n', '<Leader>tc', close_runner, { desc = 'Close the test runner pane' })
