
local hooks = require("ibl.hooks")
hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
  vim.api.nvim_set_hl(0, "IndentScopeHighlight", { fg = "#737475", bold = false })
end)


require('ibl').setup({
  exclude = {
    filetypes = {
      'help',
      'terminal',
      'dashboard',
      'packer',
      'lspinfo',
      'TelescopePrompt',
      'TelescopeResults',
    },
    buftypes = {
      'terminal',
      'NvimTree',
    },
  },
  indent = {
    char = '▏'
  },
  scope = {
    show_start = false,
    highlight = {
      'IndentScopeHighlight'
    }
  }
})
