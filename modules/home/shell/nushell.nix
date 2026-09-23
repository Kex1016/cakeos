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
