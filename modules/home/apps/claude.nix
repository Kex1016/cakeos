{
  config,
  lib,
  pkgs,
  ...
}:

# Claude Code hooks for the hecate shell. The hook scripts live in the hecate
# repo (scripts/claude/) and talk to the shell over its socket; this module only
# points Claude Code's settings.json at them.
#
# ~/.claude/settings.json belongs to the user, so it is never replaced. The hook
# entries are merged in on activation with jq, tagged by the hook.py path
# they run, and only those entries are touched on later runs (re-sync,
# disable). Existing hooks, and every other setting, are left as they are.
let
  cfg = config.cakeos.claude.hooks;
  settings = "${config.home.homeDirectory}/.claude/settings.json";
  stateFile = "${config.xdg.stateHome}/cakeos/claude-hooks-installed";
  script = if cfg.script == null then "" else cfg.script;

  # event -> hook entry for settings.json. Every event runs the same hook.py,
  # which reads the event's name from its input.
  entries = lib.mapAttrs (_event: o: [
    {
      hooks = [
        (
          {
            type = "command";
            command = cfg.python;
            args = [ script ];
          }
          // lib.optionalAttrs o.async { async = true; }
          // lib.optionalAttrs (o.timeout != null) { inherit (o) timeout; }
        )
      ];
    }
  ]) cfg.events;

  merge = pkgs.writeShellScript "claude-hooks-merge" ''
    set -eu
    jq=${lib.getExe pkgs.jq}
    settings=${lib.escapeShellArg settings}
    state=${lib.escapeShellArg stateFile}
    script=${lib.escapeShellArg script}
    new=${lib.escapeShellArg (builtins.toJSON (if cfg.enable then entries else { }))}

    if [ ! -e "$settings" ]; then
      [ "$new" = '{}' ] && exit 0
      mkdir -p "$(dirname "$settings")"
      echo '{}' > "$settings"
    fi
    # Never rewrite a file we cannot parse.
    "$jq" -e . "$settings" >/dev/null || { echo "claude hooks: $settings is not valid JSON, left alone" >&2; exit 0; }

    tmp=$(mktemp)
    "$jq" --arg script "$script" --argjson new "$new" '
      def ours: any(.hooks[]?; (.args // []) | index($script) != null);
      .hooks = (
        ((.hooks // {}) | map_values(map(select(ours | not))))
        as $kept
        | reduce ($new | keys[]) as $e ($kept; .[$e] = ((.[$e] // []) + $new[$e]))
        | with_entries(select(.value | length > 0))
      )
      | if .hooks == {} then del(.hooks) else . end
    ' "$settings" > "$tmp"
    if ! cmp -s "$tmp" "$settings"; then
      cp "$settings" "$settings.cakeos-bak"
      cat "$tmp" > "$settings"
    fi
    rm -f "$tmp"
    mkdir -p "$(dirname "$state")"
    ${if cfg.enable then ''touch "$state"'' else ''rm -f "$state"''}
  '';
in
{
  options.cakeos.claude.hooks = {
    enable = lib.mkEnableOption "Claude Code hooks that report to the hecate shell";
    script = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/nix/store/…-hecate-shell/…/scripts/claude/hook.py";
      description = ''
        Absolute path of hook.py in the hecate shell's scripts/claude/. Required when
        enabled. Hook entries whose args name this path are the ones this module owns.
      '';
    };
    python = lib.mkOption {
      type = lib.types.str;
      default = lib.getExe pkgs.python3;
      defaultText = lib.literalExpression "lib.getExe pkgs.python3";
      description = "Python 3 interpreter that runs hook.py (standard library only).";
    };
    events = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            async = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Run without holding Claude Code up. Only PermissionRequest answers, so it is not async.";
            };
            timeout = lib.mkOption {
              type = lib.types.nullOr lib.types.int;
              default = null;
              description = "Hook timeout in seconds; null keeps Claude Code's default.";
            };
          };
        }
      );
      default = {
        PermissionRequest = {
          async = false;
          timeout = 3600;
        };
        SessionStart = { };
        UserPromptSubmit = { };
        PreToolUse = { };
        PostToolUse = { };
        PostToolUseFailure = { };
        Notification = { };
        SubagentStart = { };
        SubagentStop = { };
        Stop = {
          async = false;
          timeout = 5;
        };
        StopFailure = {
          async = false;
          timeout = 5;
        };
        SessionEnd.async = false;
      };
      description = "Hook events to register, mirroring the bridge's hooks.example.json.";
    };
  };

  config = {
    assertions = lib.optional cfg.enable {
      assertion = cfg.script != null;
      message = "cakeos.claude.hooks.script must be set when the Claude hooks are enabled.";
    };

    home.packages = lib.mkIf cfg.enable [ pkgs.jq ];

    # Runs when enabled, and once more after disabling to take our entries back
    # out (the marker file means we installed some).
    home.activation.claudeHooks = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      if cfg.enable then
        ''run ${merge}''
      else
        ''[ ! -e ${lib.escapeShellArg stateFile} ] || run ${merge}''
    );
  };
}
