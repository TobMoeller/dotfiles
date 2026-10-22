-- Run inside the complete configured editor; use a temporary XDG environment.
local function run()
  local directory = vim.fn.tempname()
  vim.fn.mkdir(directory, 'p')
  local function fixture(name, lines)
    local path = directory .. '/' .. name
    vim.fn.writefile(lines, path)
    return path
  end
  local function edit(path)
    vim.v.errmsg = ''
    vim.cmd.edit(vim.fn.fnameescape(path))
    vim.wait(100)
    assert(vim.v.errmsg == '', vim.v.errmsg)
  end
  local large = require('dotfiles.large-files')
  local normal = fixture('small.lua', { 'local answer = 42', 'print(answer)' })
  local many_lines = fixture('many.lua', vim.fn['repeat']({ '-- short line' }, 20001))
  local minified = fixture('minified.json', { '{"data":"' .. string.rep('a', 8000) .. '"}' })
  local big = fixture('large.json', { '{"data":"' .. string.rep('a', 2 * 1024 * 1024) .. '"}' })

  edit(normal)
  assert(not large.is_large(0), 'small source incorrectly treated as large')
  assert(vim.bo.filetype == 'lua')
  assert(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()], 'Lua highlighting missing')
  assert(require('cmp').get_config().enabled(), 'normal completion disabled')
  assert(vim.bo.syntax == '', 'regex highlighting duplicates Treesitter')
  assert(vim.fn.maparg('<C-h>', 'n') ~= '', 'herdr navigation missing')
  assert(vim.fn.maparg('<leader>tn', 'n') ~= '', 'test runner mapping missing')
  local left = vim.api.nvim_get_current_win()
  vim.cmd.vsplit()
  vim.fn.maparg('<C-h>', 'n', false, true).callback()
  assert(vim.api.nvim_get_current_win() == left, 'Ctrl-h did not navigate within Neovim')
  local system, pane, binary = vim.system, vim.env.HERDR_PANE_ID, vim.env.HERDR_BIN_PATH
  local navigation
  vim.env.HERDR_PANE_ID, vim.env.HERDR_BIN_PATH = 'test-pane', 'herdr-test-double'
  vim.system = function(command, _, callback)
    navigation = command
    callback({ code = 0, stderr = '' })
  end
  vim.fn.maparg('<C-h>', 'n', false, true).callback()
  vim.system, vim.env.HERDR_PANE_ID, vim.env.HERDR_BIN_PATH = system, pane, binary
  assert(vim.deep_equal(navigation, { 'herdr-test-double', 'pane', 'focus', '--direction', 'left', '--pane', 'test-pane' }),
    'Ctrl-h did not cross the Neovim edge through the herdr CLI')
  vim.cmd.only()
  vim.api.nvim_win_set_cursor(0, { 1, 6 })
  vim.fn.maparg('v<CR>', 'n', false, true).callback()
  assert(vim.fn.mode() == 'v', 'syntax selection did not enter visual mode')
  vim.fn.maparg('<Tab>', 'x', false, true).callback()
  vim.fn.maparg('<S-Tab>', 'x', false, true).callback()
  vim.cmd.normal({ vim.keycode('<Esc>'), bang = true })
  local buffer_source = vim.iter(require('cmp').get_config().sources):find(function(s) return s.name == 'buffer' end)
  assert(vim.deep_equal(buffer_source.option.get_bufnrs(), { vim.api.nvim_get_current_buf() }))

  for _, path in ipairs({ many_lines, minified, big }) do
    edit(path)
    local buf = vim.api.nvim_get_current_buf()
    assert(large.is_large(buf), 'large-file guard missing: ' .. path)
    assert(not vim.treesitter.highlighter.active[buf], 'large file still parsed')
    assert(not require('cmp').get_config().enabled(), 'large file still autocompletes')
    assert(#buffer_source.option.get_bufnrs() == 0, 'large buffer still scanned for words')
    assert(not vim.wo.spell, 'large file still spellchecked')
    assert(#vim.lsp.get_clients({ bufnr = buf }) == 0, 'LSP attached to large file')
    assert(vim.bo.undolevels ~= -1, 'undo unexpectedly disabled')
    assert(not vim.bo.readonly, 'large file unexpectedly read-only')
  end

  edit(normal)
  assert(not large.is_large(0), 'guard leaked to normal buffer')
  assert(require('cmp').get_config().enabled(), 'completion did not recover')
  assert(vim.wo.spell, 'spell setting leaked to normal buffer')
  local root
  vim.lsp.config.laravel_lsp.root_dir(0, function(dir) root = dir end)
  assert(root == nil, 'Laravel server started outside Laravel')
  fixture('artisan', { '<?php' })
  vim.lsp.config.laravel_lsp.root_dir(0, function(dir) root = dir end)
  assert(root == directory, 'Laravel root not recognized')
  assert(vim.lsp.config.laravel_lsp.init_options.pestGenerateDocBlocks == false)
  assert(vim.fn.executable('laravel-lsp') == 1, 'Laravel binary missing')
  vim.cmd.enew()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { string.rep('x', 8000) })
  vim.api.nvim_exec_autocmds('TextChanged', { buffer = 0 })
  assert(large.is_large(0), 'newly edited long line was not detected')
  vim.cmd('silent! bwipeout!')
  vim.fn.delete(directory, 'rf')
  print('Neovim smoke tests passed: startup, highlighting, completion, large files, Laravel roots')
end

local ok, err = xpcall(run, debug.traceback)
if not ok then
  io.stderr:write(err .. '\n')
  vim.cmd.cquit(1)
end
