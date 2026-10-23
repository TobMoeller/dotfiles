{
  flake.modules.homeManager.local-ai =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.localAI.whisperPackage = lib.mkPackageOption pkgs "whisper-cpp" { };

      config = {
        services.ollama = {
          enable = true;
          host = "127.0.0.1";
          environmentVariables = {
            OLLAMA_MODELS = "${config.xdg.dataHome}/ollama/models";
            OLLAMA_CONTEXT_LENGTH = "8192";
            OLLAMA_NUM_PARALLEL = "1";
            OLLAMA_MAX_LOADED_MODELS = "1";
            OLLAMA_KEEP_ALIVE = "1m";
            OLLAMA_NO_CLOUD = "1";
          };
        };
        home.packages = [
          config.localAI.whisperPackage
          pkgs.ffmpeg-headless
          pkgs.aider-chat
        ];
        home.file.".aider.model.settings.yml".source =
          config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.repositoryPath}/modules/features/local-ai/aider-model-settings.yml";
        systemd.user.services.ollama.Service = {
          Restart = "on-failure";
          RestartSec = 3;
        };
      };
    };
}
