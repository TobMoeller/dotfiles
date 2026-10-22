local function run()
  local directory = vim.fn.tempname()
  vim.fn.mkdir(directory, 'p')
  vim.fn.writefile({ '<?php', '// Isolated LSP test project, no application bootstrap.' }, directory .. '/artisan')
  vim.fn.writefile({ '{"name":"dotfiles/lsp-test","require":{}}' }, directory .. '/composer.json')
  vim.fn.writefile({ '<?php', '$value = 42;', 'echo $value;' }, directory .. '/test.php')
  vim.cmd.edit(directory .. '/test.php')
  local ready = vim.wait(20000, function()
    local initialized = {}
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
      if client.initialized then initialized[client.name] = true end
    end
    return initialized.intelephense and initialized.laravel_lsp
  end, 50)
  assert(ready, 'PHP and Laravel servers did not both initialize; check :LspLog')
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    assert(client.server_capabilities.completionProvider, client.name .. ' lacks completion')
  end

  local blade = directory .. '/test.blade.php'
  vim.fn.writefile({ '<div>{{ $value }}</div>' }, blade)
  vim.cmd.edit(blade)
  assert(vim.bo.filetype == 'blade', 'Blade filetype missing')
  assert(vim.wait(5000, function()
    return #vim.lsp.get_clients({ bufnr = 0, name = 'laravel_lsp' }) == 1
  end), 'Laravel server did not attach to Blade')
  assert(#vim.lsp.get_clients({ bufnr = 0, name = 'intelephense' }) == 0, 'PHP parser attached to Blade')

  for _, client in ipairs(vim.lsp.get_clients()) do client:stop(true) end
  vim.fn.delete(directory, 'rf')
  print('LSP tests passed: Intelephense + official Laravel initialize, Blade attaches only to Laravel')
end
local ok, err = xpcall(run, debug.traceback)
if not ok then
  io.stderr:write(err .. '\n')
  vim.cmd.cquit(1)
end
