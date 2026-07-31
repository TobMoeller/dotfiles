{ config, pkgs, lib, cmp-ai, ... }:

{
    programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;

        initLua = lib.fileContents ./config/neovim/config.lua;

        plugins = with pkgs.vimPlugins; [
            {
                plugin = catppuccin-nvim;
                type = "lua";
                config = ''
                    vim.opt.termguicolors = true
                    require("catppuccin").setup({
                        flavour = "mocha",
                        integrations = {
                            cmp = true,
                            nvimtree = true,
                            telescope = {
                                enabled = true,
                            },
                        }
                    })
                    vim.cmd.colorscheme "catppuccin-mocha"
                '';
            }
            # Commenting Support
            vim-commentary
            # Add, change, and delete surrounding text.
            vim-surround
            # Useful commands like :Rename and :SudoWrite.
            vim-eunuch
            # Pairs of handy bracket mappings, like [b and ]b.
            vim-unimpaired
            # Indent autodetection with editorconfig support.
            vim-sleuth
            # indentation lines
            {
                plugin = indent-blankline-nvim;
                type = "lua";
                config = lib.fileContents ./config/neovim/indent-blankline.lua;
            }
            # Allow plugins to enable repeating of commands with "."
            vim-repeat
            # Add more languages.
            # vim-polyglot
            # Seamless <C-hjkl> between Neovim splits and herdr panes (our herdr
            # port; still falls back to tmux when not inside herdr). Disables the
            # plugin's own tmux mappings and installs mappings that wincmd within
            # nvim, then cross into the multiplexer at a split edge. The herdr
            # side (vim-nav plugin) forwards the key here when nvim/fzf is focused.
            {
                plugin = vim-tmux-navigator;
                type = "lua";
                config = ''
                    vim.g.tmux_navigator_no_mappings = 1
                    local function nav(wincmd, dir)
                        local prev = vim.api.nvim_get_current_win()
                        vim.cmd("wincmd " .. wincmd)
                        if vim.api.nvim_get_current_win() ~= prev then return end
                        -- at a split edge: cross into the surrounding multiplexer
                        if vim.env.HERDR_PANE_ID and vim.env.HERDR_PANE_ID ~= "" then
                            local herdr = vim.env.HERDR_BIN_PATH
                            if herdr == nil or herdr == "" then herdr = "herdr" end
                            vim.fn.system({ herdr, "pane", "focus", "--direction", dir, "--current" })
                        elseif vim.env.TMUX and vim.env.TMUX ~= "" then
                            local t = { left = "Left", down = "Down", up = "Up", right = "Right" }
                            pcall(vim.cmd, "TmuxNavigate" .. t[dir])
                        end
                    end
                    local function map(lhs, wincmd, dir)
                        vim.keymap.set("n", lhs, function() nav(wincmd, dir) end,
                            { silent = true, desc = "Navigate " .. dir .. " (vim/herdr)" })
                    end
                    map("<C-h>", "h", "left")
                    map("<C-j>", "j", "down")
                    map("<C-k>", "k", "up")
                    map("<C-l>", "l", "right")
                '';
            }
            # Jump to the last location when opening a file.
            vim-lastplace
            # Enable * searching with visually selected text.
            vim-visual-star-search
            # highlight yanked text
            {
                plugin = vim-highlightedyank;
                type = "lua";
                config = ''
                    vim.g.highlightedyank_highlight_duration = 400
                '';
            }
            # sets cwd to project root, ran only on nvim startup
            {
                plugin = vim-rooter;
                type = "lua";
                config = ''
                    vim.g.rooter_manual_only = 1
                    vim.api.nvim_create_autocmd("VimEnter", {
                        pattern = "*",
                        callback = function()
                            vim.cmd('Rooter')
                        end
                    })
                '';
            }
            {
                plugin = nvim-autopairs;
                type = "lua";
                config = ''
                    require('nvim-autopairs').setup({})
                '';
            }
            {
                plugin = bufdelete-nvim;
                type = "lua";
                config = "vim.keymap.set('n', '<Leader>q', ':Bdelete<CR>')";
            }
            {
                plugin = treesj;
                type = "lua";
                config = ''
                    local treesj = require('treesj')
                    treesj.setup({use_default_keymaps = false})
                    vim.keymap.set('n', 'gJ', treesj.join)
                    vim.keymap.set('n', 'gS', treesj.split)
                '';
            }
            {
                plugin = telescope-nvim;
                type = "lua";
                config = lib.fileContents ./config/neovim/telescope.lua;
            }
            plenary-nvim
            telescope-live-grep-args-nvim
            telescope-fzf-native-nvim
            {
                plugin = nvim-tree-lua;
                type = "lua";
                config = lib.fileContents ./config/neovim/nvim-tree.lua;
            }
            nvim-web-devicons
            {
                plugin = lualine-nvim;
                type = "lua";
                config = lib.fileContents ./config/neovim/lualine.lua;
            }
            {
                plugin = bufferline-nvim;
                type = "lua";
                config = lib.fileContents ./config/neovim/bufferline.lua;
            }
            {
                plugin = nvim-treesitter.withAllGrammars;
                type = "lua";
                config = lib.fileContents ./config/neovim/treesitter.lua;
            }
            nvim-ts-context-commentstring
            nvim-treesitter-textobjects
            {
                plugin = gitsigns-nvim;
                type = "lua";
                config = lib.fileContents ./config/neovim/gitsigns.lua;
            }
            diffview-nvim
            {
                plugin = neogit;
                type = "lua";
                config = ''
                    require('neogit').setup()
                    vim.keymap.set('n', '<Leader>g', ':Neogit<CR>')
                '';
            }

            # interact with tmux from vim
            {
                plugin = vimux;
                type = "lua";
                config = ''
                    vim.g.VimuxHeight = '50'
                    vim.g.VimuxOrientation = 'h'
                '';
            }
            # Test execution
            {
                plugin = vim-test;
                type = "lua";
                config = ''
                    vim.keymap.set('n', '<Leader>tn', ':TestNearest<CR>')
                    vim.keymap.set('n', '<Leader>tf', ':TestFile<CR>')
                    vim.keymap.set('n', '<Leader>tl', ':TestLast<CR>')
                    vim.g['test#strategy'] = 'vimux'
                '';
            }
            
            # ------------------
            # LSPs
            # ------------------
            {
                plugin = nvim-lspconfig;
                type = "lua";
                config = lib.fileContents ./config/neovim/lsp-config.lua;
            }
            {
                plugin = nvim-cmp;
                type = "lua";
                config = lib.fileContents ./config/neovim/cmp.lua;
            }
            cmp-nvim-lsp # lsp completion
            cmp-nvim-lsp-signature-help # function signature for completion
            cmp-buffer # completion for buffer words
            cmp-path # completion for path
            friendly-snippets
            luasnip
            cmp_luasnip # completion for luasnip
            lspkind-nvim # icons for completion

            # {
            #     plugin =
            #       (pkgs.vimUtils.buildVimPlugin {
            #         name = "cmp-ai";
            #         src = cmp-ai;
            #       });
            #     type = "lua";
            #     config = lib.fileContents ./config/neovim/cmp-ai.lua;
            # }

            # TODO not implemented yet:
            # vim-heritage
            # vim-textobj-xmlattr
            # vim-textobj-user
        ];
    };
}
