{
  flake.modules.homeManager.git = {
    programs.git = {
      enable = true;
      settings = {
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
        alias = {
          s = "status -sb";
          st = "status";
          ci = "commit";
          co = "checkout";
        };
      };
    };
  };
}
