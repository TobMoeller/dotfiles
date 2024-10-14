{ config, pkgs, lib, ... }:

{
    programs.zsh = {
        enable = true;

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
}
