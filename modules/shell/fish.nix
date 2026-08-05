{ ... }:
{
  flake.modules.homeManager.base =
    { config, ... }:
    {
      programs.starship = {
        enable = true;
        enableFishIntegration = true;
      };
      programs.fish = {
        enable = true;
        functions = {
          fish_greeting = "fastfetch";
          command_not_found_handler = {
            onEvent = "fish_command_not_found";
            body = ''
              # $argv[1] is the command the user typed
              set -l cmd $argv[1]

              # Append the command name to the log file
              echo $cmd >> ~/.cakemisc/failed_commands.log
            '';
          };
        };
        shellAliases = {
          convene = "cd $HOME/.nixos/universe && git pull && nix flake update";
          ritual = "convene && sacrifice";
          cp = "/run/current-system/sw/bin/cp --reflink=auto -v";
          rm = "trash --trash-dir ${config.home.homeDirectory}/Trash";
          btw = "fastfetch";
          df = "duf";
          du = "dust";
          rungame = "gamescope --backend wayland -W 2560 -H 1080 -w 2560 -h 1080 --force-grab-cursor -r 200 --expose-wayland -- ";
          cargodoc = "cargo tree --depth 1 -e normal --prefix none | cut -d' ' -f1 | xargs printf -- '-p %s\n' | xargs cargo doc --no-deps";
        };
      };
    };
}
