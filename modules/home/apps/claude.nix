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
# entries are merged in on activation with jq, tagged by the scripts directory
# they point at, and only those entries are touched on later runs (re-sync,
# disable). Existing hooks, and every other setting, are left as they are.
let
  cfg = config.cakeos.claude.hooks;
  settings = "${config.home.homeDirectory}/.claude/settings.json";
  stateFile = "${config.xdg.stateHome}/cakeos/claude-hooks-installed";

  # event -> hook entry for settings.json
  entries = lib.mapAttrs (_event: script: [
    {
      hooks = [
        {
          type = "command";
          command = "${cfg.scriptsDir}/${script}";
        }
      ];
    }
  ]) cfg.events;

  merge = pkgs.writeShellScript "claude-hooks-merge" ''
    set -eu
    jq=${lib.getExe pkgs.jq}
    settings=${lib.escapeShellArg settings}
    state=${lib.escapeShellArg stateFile}
    dir=${lib.escapeShellArg cfg.scriptsDir}
    new=${lib.escapeShellArg (builtins.toJSON (if cfg.enable then entries else { }))}

    if [ ! -e "$settings" ]; then
      [ "$new" = '{}' ] && exit 0
      mkdir -p "$(dirname "$settings")"
      echo '{}' > "$settings"
    fi
    # Never rewrite a file we cannot parse.
    "$jq" -e . "$settings" >/dev/null || { echo "claude hooks: $settings is not valid JSON, left alone" >&2; exit 0; }

    tmp=$(mktemp)
    "$jq" --arg dir "$dir" --argjson new "$new" '
      def ours: any(.hooks[]?; (.command // "") | startswith($dir + "/"));
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
    scriptsDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.local/share/hecate/scripts/claude";
      defaultText = lib.literalExpression ''"''${config.home.homeDirectory}/.local/share/hecate/scripts/claude"'';
      description = ''
        Directory holding the hecate shell's Claude hook scripts (scripts/claude/ in
        the hecate repo). Hook entries whose command lies under it are the ones this
        module owns.
      '';
    };
    events = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        Notification = "notification.sh";
        Stop = "stop.sh";
        SubagentStop = "subagent-stop.sh";
        UserPromptSubmit = "user-prompt-submit.sh";
        PreToolUse = "pre-tool-use.sh";
        PostToolUse = "post-tool-use.sh";
      };
      description = "Claude Code hook event to the script in scriptsDir that handles it.";
    };
  };

  config = {
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
