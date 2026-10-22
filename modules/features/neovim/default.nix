{
  flake.modules.homeManager.neovim =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
        withPython3 = false;
        withRuby = false;
        withNodeJs = false;
        # Keep Home Manager's provider stub in the wrapper, not in init.lua.
        sideloadInitLua = true;

        # Nix provides plugins and tools; all interactive configuration is Lua.
        plugins = with pkgs.vimPlugins; [
          catppuccin-nvim
          vim-surround
          vim-eunuch
          vim-unimpaired
          vim-sleuth
          vim-repeat
          vim-visual-star-search
          indent-blankline-nvim
          nvim-autopairs
          bufdelete-nvim
          treesj
          telescope-nvim
          plenary-nvim
          telescope-live-grep-args-nvim
          telescope-fzf-native-nvim
          nvim-tree-lua
          nvim-web-devicons
          lualine-nvim
          bufferline-nvim
          (nvim-treesitter.withPlugins (
            p: with p; [
              bash
              blade
              c
              css
              dart
              diff
              dockerfile
              go
              gomod
              html
              javascript
              jsdoc
              json
              lua
              luadoc
              markdown
              markdown_inline
              nix
              php
              phpdoc
              python
              regex
              rust
              sql
              swift
              toml
              tsx
              typescript
              vim
              vimdoc
              vue
              yaml
              zig
            ]
          ))
          nvim-treesitter-textobjects
          gitsigns-nvim
          diffview-nvim
          neogit
          vim-test
          nvim-lspconfig
          nvim-cmp
          cmp-nvim-lsp
          cmp-nvim-lsp-signature-help
          cmp-buffer
          cmp-path
          friendly-snippets
          luasnip
          cmp_luasnip
          lspkind-nvim
        ];

        # Suffix PATH: a project's devShell can supply its own tool versions.
        extraPackages =
          with pkgs;
          [
            ripgrep
            fd
            git
            intelephense
            (callPackage ./laravel-lsp.nix { })
            typescript
            typescript-language-server
            tailwindcss-language-server
            pyright
            lua-language-server
            nil
          ]
          ++ lib.optionals pkgs.stdenv.isLinux [
            wl-clipboard
            xclip
          ];
      };

      xdg.configFile."nvim".source =
        config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.repositoryPath}/modules/features/neovim/config";
    };
}
