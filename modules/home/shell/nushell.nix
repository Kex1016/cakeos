{ config, ... }:

{
  programs.starship = {
    enable = true;
    enableNushellIntegration = true;
  };

  # Nushell has no completions for external commands on its own; carapace
  # fills the gap that fish's own completions used to cover.
  programs.carapace = {
    enable = true;
    enableNushellIntegration = true;
  };

  programs.nushell = {
    enable = true;

    settings = {
      show_banner = false;
      edit_mode = "emacs";
      completions = {
        algorithm = "fuzzy";
        case_sensitive = false;
      };
    };

    shellAliases = {
      cp = "^/run/current-system/sw/bin/cp --reflink=auto -v";
      rm = "^trash --trash-dir ${config.home.homeDirectory}/Trash";
      btw = "fastfetch";
      df = "duf";
      du = "dust";
      rungame = "^gamescope --backend wayland -W 2560 -H 1080 -w 2560 -h 1080 --force-grab-cursor -r 200 --expose-wayland --";
    };

    extraConfig = ''
      # Log commands that could not be found. Replaces the fish
      # `command_not_found_handler` function.
      $env.config.hooks.command_not_found = {|cmd|
          let dir = ($nu.home-dir | path join ".cakemisc")
          mkdir $dir
          $"($cmd)\n" | save --append ($dir | path join "failed_commands.log")
          null
      }

      # `--env` so the `cd` sticks after the command returns, the way the fish
      # alias behaved.
      def --env convene [] {
          cd ($nu.home-dir | path join ".nixos" "universe")
          ^git pull
          ^nix flake update
      }

      # NOTE: the fish config aliased this to `convene && sacrifice`, but
      # `sacrifice` was never defined anywhere in the repo, so the second half
      # was dead. Only the `convene` part is carried over.
      def --env ritual [] {
          convene
      }

      # `cargo doc` for direct dependencies only.
      def cargodoc [] {
          let direct = (
              ^cargo tree --depth 1 -e normal --prefix none
              | lines
              | each { |line| $line | split row " " | first }
              | where { |name| $name != "" }
              | uniq
          )
          ^cargo doc --no-deps ...($direct | each { |name| ["-p" $name] } | flatten)
      }

      # Nushell loads this file for scripts as well as for interactive shells,
      # so the greeting has to be guarded or every `#!/usr/bin/env nu` script
      # would print it.
      if $nu.is-interactive {
          fastfetch
      }
    '';
  };
}
