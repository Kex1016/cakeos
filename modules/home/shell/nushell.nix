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
    # Keep the pre-26.11 default (and silence its warning).
    loadSessionVariables = false;

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

    # `home.sessionPath` only reaches POSIX shells (hm-session-vars.sh), so put
    # ~/.local/bin (the cakeos scripts) on nushell's PATH here.
    extraEnv = ''
      $env.PATH = (
          $env.PATH
          | split row (char esep)
          | prepend "${config.home.homeDirectory}/.local/bin"
          | uniq
      )
    '';

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

      # A command that fails after running 10 s or more is written to
      # failed-command.json for the hecate shell's "ask Claude" toast. The
      # shell's state dir only exists under hecate, so elsewhere this does nothing.
      $env.config.hooks.pre_execution = (
          ($env.config.hooks?.pre_execution? | default [])
          | append {||
              $env.CAKEOS_LAST_COMMAND = (commandline)
          }
      )
      $env.config.hooks.pre_prompt = (
          ($env.config.hooks?.pre_prompt? | default [])
          | append {||
              let command = ($env.CAKEOS_LAST_COMMAND? | default "")
              $env.CAKEOS_LAST_COMMAND = ""
              let status = ($env.LAST_EXIT_CODE? | default 0)
              let duration = ($env.CMD_DURATION_MS? | default "0" | into int)
              let dir = (
                  $env.XDG_STATE_HOME? | default ($nu.home-dir | path join ".local/state")
                  | path join "quickshell/user"
              )
              # 130 is Ctrl-C: nothing failed, the user stopped it.
              if $command != "" and $status != 0 and $status != 130 and $duration >= 10000 and ($dir | path exists) {
                  {
                      command: $command
                      status: $status
                      durationMs: $duration
                      cwd: (pwd)
                      output: ""
                  } | to json | save --force ($dir | path join "failed-command.json")
              }
          }
      )

      # Nushell loads this file for scripts as well as for interactive shells,
      # so the greeting has to be guarded or every `#!/usr/bin/env nu` script
      # would print it.
      if $nu.is-interactive {
          fastfetch
      }
    '';
  };
}
