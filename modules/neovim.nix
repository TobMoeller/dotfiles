{ config, pkgs, ... }:
let
  darcula = pkgs.vimUtils.buildVimPlugin {
    pname = "darcula";
    version = "faf8dbab";
    src = pkgs.fetchFromGitHub {
      owner = "doums";
      repo = "darcula";
      rev = "faf8dbab27bee0f27e4f1c3ca7e9695af9b1242b";
      sha256 = "0pwq4lb6q1a25vmlimaxcfxjh10qfvc7wdqqskyqlj1iasdaazqs";
    };
  };
  dark = pkgs.vimUtils.buildVimPlugin {
    pname = "dark.nvim";
    version = "9ea54434";
    src = pkgs.fetchFromGitHub {
      owner = "doums";
      repo = "dark.nvim";
      rev = "9ea54434c5f3b2b2974ea5ea0ae47872a754f8a6";
      sha256 = "0a5acy6n3g80zvcir2vrkzvmqq4l40mhvkj2bxbkqvi1y9wwc5fv";
    };
  };
in {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    plugins = with pkgs.vimPlugins; [
      catppuccin-nvim tokyonight-nvim dracula-nvim darcula dark
      vim-commentary vim-surround vim-eunuch vim-unimpaired vim-sleuth
      vim-repeat vim-lastplace vim-visual-star-search vim-highlightedyank
      vim-rooter vim-tmux-navigator nvim-autopairs bufdelete-nvim treesj
      indent-blankline-nvim
      telescope-nvim telescope-live-grep-args-nvim telescope-fzf-native-nvim
      plenary-nvim oil-nvim nvim-tree-lua nvim-web-devicons
      lualine-nvim bufferline-nvim
      nvim-treesitter.withAllGrammars nvim-treesitter-textobjects
      nvim-ts-context-commentstring
      gitsigns-nvim diffview-nvim neogit vimux vim-test
      nvim-lspconfig mason-nvim nvim-cmp cmp-nvim-lsp
      cmp-nvim-lsp-signature-help cmp-buffer cmp-path
      friendly-snippets luasnip cmp_luasnip lspkind-nvim
    ];
  };
  home.packages = with pkgs; [
    git curl unzip gnutar gzip python3 ripgrep fd
    intelephense typescript-language-server tailwindcss-language-server pyright
  ];
  home.sessionVariables.VISUAL = "nvim";
  xdg.configFile."nvim/init.lua".source = config.lib.file.mkOutOfStoreSymlink
    "${config.dotfiles.repoRoot}/config/nvim/init.lua";
  xdg.configFile."nvim/lua/config".source = config.lib.file.mkOutOfStoreSymlink
    "${config.dotfiles.repoRoot}/config/nvim/lua/config";
}
