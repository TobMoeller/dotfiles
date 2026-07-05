{ config, pkgs, lib, ... }:

{
    programs.zsh = {
        enable = true;

        initContent = lib.mkMerge [
            # Source machine-local secrets (API keys, tokens) that must never be
            # committed. Create ~/.secrets.env yourself (chmod 600); exported vars
            # become available to anything launched from the shell, e.g. Claude
            # Code MCP servers that reference ${CONTEXT7_API_KEY} in their config.
            (lib.mkOrder 550 ''
                [ -f "$HOME/.secrets.env" ] && source "$HOME/.secrets.env"
            '')

            # Additions kept out of the (mostly pure) zsh.nix. custom.zsh is
            # tracked in git and symlinked from the working tree (see home.file
            # below), so edits apply in any new shell without a home-manager
            # switch. local.zsh is untracked, machine-specific, and optional;
            # sourced last so it can override anything above.
            (lib.mkOrder 1000 ''
                [ -f "$HOME/.zsh/custom.zsh" ] && source "$HOME/.zsh/custom.zsh"
                [ -f "$HOME/.zsh/local.zsh" ] && source "$HOME/.zsh/local.zsh"
            '')
        ];

        shellAliases = {
            ll = "ls -alF";
            la = "ls -A";
            l = "ls -CF";

            ".." = "cd ..";
            "..." = "cd ../..";
            "...." = "cd ../../..";
            "....." = "cd ../../../..";

            pa = "php artisan";
            sail = "./vendor/bin/sail";

            ide = "php artisan ide-helper:generate && php artisan ide-helper:models -N && php artisan ide-helper:meta";

            k = "kubectl";

            p = "podman";
            pc = "podman-compose";
            d = "docker";
            dc = "docker compose";
            phpdbg = "XDEBUG_CONFIG=\"idekey=PHPSTORM\" php -dxdebug.mode=debug $@";
        };
        
        plugins = [
            {
                name = "powerlevel10k";
                src = pkgs.zsh-powerlevel10k;
                file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
            }
            {
                name = "powerlevel10k-config";
                src = lib.cleanSource ./config;
                file = "p10k.zsh";
            }
            # https://github.com/jeffreytse/zsh-vi-mode
            {
                name = "vi-mode";
                src = pkgs.zsh-vi-mode;
                file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
            }
        ];
    };

    # Symlink custom.zsh to the file in the working tree (not the nix store), so
    # editing it takes effect immediately without a home-manager switch. The
    # target path must exist on the machine for the symlink to resolve.
    home.file.".zsh/custom.zsh".source =
        config.lib.file.mkOutOfStoreSymlink
            "${config.home.homeDirectory}/code/tobmoeller/dotfiles/home-manager/packages/config/zsh/custom.zsh";
}
