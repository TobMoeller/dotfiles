return function(bufnr)
    local gitsigns = require('gitsigns')

    local descriptions = {
      ["]c"] = "Next Git hunk", ["[c"] = "Previous Git hunk",
      ["<leader>hs"] = "Stage hunk", ["<leader>hr"] = "Reset hunk",
      ["<leader>hS"] = "Stage buffer", ["<leader>hu"] = "Undo stage hunk",
      ["<leader>hR"] = "Reset buffer", ["<leader>hp"] = "Preview hunk",
      ["<leader>hb"] = "Blame line", ["<leader>tb"] = "Toggle line blame",
      ["<leader>hd"] = "Diff index", ["<leader>hD"] = "Diff previous commit",
      ["<leader>td"] = "Preview hunk inline", ih = "Select Git hunk",
    }
    local function map(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      opts.desc = descriptions[l]
      vim.keymap.set(mode, l, r, opts)
    end

    -- Navigation
    map('n', ']c', function()
      if vim.wo.diff then
        vim.cmd.normal({']c', bang = true})
      else
        gitsigns.nav_hunk('next')
      end
    end)

    map('n', '[c', function()
      if vim.wo.diff then
        vim.cmd.normal({'[c', bang = true})
      else
        gitsigns.nav_hunk('prev')
      end
    end)

    -- Actions
    map('n', '<leader>hs', gitsigns.stage_hunk)
    map('n', '<leader>hr', gitsigns.reset_hunk)
    map('v', '<leader>hs', function() gitsigns.stage_hunk {vim.fn.line('.'), vim.fn.line('v')} end)
    map('v', '<leader>hr', function() gitsigns.reset_hunk {vim.fn.line('.'), vim.fn.line('v')} end)
    map('n', '<leader>hS', gitsigns.stage_buffer)
    map('n', '<leader>hu', gitsigns.undo_stage_hunk)
    map('n', '<leader>hR', gitsigns.reset_buffer)
    map('n', '<leader>hp', gitsigns.preview_hunk)
    map('n', '<leader>hb', function() gitsigns.blame_line{full=true} end)
    map('n', '<leader>tb', gitsigns.toggle_current_line_blame)
    map('n', '<leader>hd', gitsigns.diffthis)
    map('n', '<leader>hD', function() gitsigns.diffthis('~') end)
    map('n', '<leader>td', gitsigns.preview_hunk_inline)

    -- Text object
    map({'o', 'x'}, 'ih', ':<C-U>Gitsigns select_hunk<CR>')
end
