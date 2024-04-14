{ config, pkgs, lib, cmp-ai, ... }:

{
    programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;

        extraLuaConfig = lib.fileContents ./config/neovim/config.lua;

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
            vim-polyglot
            # Navigate seamlessly between Vim windows and Tmux panes.
            vim-tmux-navigator
            # Jump to the last location when opening a file.
            vim-lastplace
            # Enable * searching with visually selected text.
            vim-visual-star-search
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
                plugin = splitjoin-vim;
                type = "lua";
                config = ''
                    vim.g.splitjoin_html_attributes_hanging = 1
                    vim.g.splitjoin_trailing_comma = 1
                    vim.g.splitjoin_php_method_chain_full = 1
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
                config = "require('gitsigns').setup()";
            }
            diffview-nvim
            {
                plugin = neogit;
                type = "lua";
                config = "require('neogit').setup()";
            }

            # Test execution
            {
                plugin = vimux;
                type = "lua";
                config = ''
                    vim.g.VimuxHeight = '50'
                    vim.g.VimuxOrientation = 'h'
                '';
            }
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
            
            # LSPs
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
