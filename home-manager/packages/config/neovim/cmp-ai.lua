local cmp_ai = require('cmp_ai.config')

cmp_ai:setup({
  max_lines = 200,
  provider = 'Ollama',
  provider_options = {
    model = 'codellama:7b-code',
    base_url = 'http://localllm:11434/api/generate',
  },
  notify = true,
  notify_callback = function(msg)
  vim.notify(msg)
  end,
  run_on_every_keystroke =  false,
  ignored_file_types = {
    -- default is not to ignore
    -- uncomment to ignore in lua:
    -- lua = true
  },
})
