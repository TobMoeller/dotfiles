{ config, pkgs, lib, ... }:

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
            # TODO temporary disabled, slow startup
            # {
            #     plugin = vim-rooter;
            #     type = "lua";
            #     config = ''
            #         vim.g.rooter_manual_only = 1
            #         vim.cmd.Rooter
            #     '';
            # }
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

            # TODO not implemented yet:
            # vim-heritage
            # vim-textobj-xmlattr
            # vim-textobj-user
        ];
    };
}