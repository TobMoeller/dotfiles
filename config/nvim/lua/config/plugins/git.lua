require("gitsigns").setup({ on_attach = require("config.keymaps.git") })
require("neogit").setup({ integrations = { telescope = true, diffview = true } })
