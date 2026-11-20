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
#
# The rest of the Claude Code side of the hecate desktop lives here too, each part
# off until switched on: the CLI (cakeos.claude.cli), hecate-mcp registered as an
# MCP server (cakeos.claude.mcp) and the shell's own Claude switch
# (cakeos.claude.shell).
let
  cfg = config.cakeos.claude.hooks;
  cli = config.cakeos.claude.cli;
  mcp = config.cakeos.claude.mcp;
  shell = config.cakeos.claude.shell;
  tomlFormat = pkgs.formats.toml { };
  shellConfig = "${config.xdg.configHome}/illogical-impulse/config.json";
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
          timeout = 86400;
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

  options.cakeos.claude.cli = {
    enable = lib.mkEnableOption "the Claude Code CLI";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.claude-code;
      defaultText = lib.literalExpression "pkgs.claude-code";
      description = ''
        The Claude Code CLI, pinned by the flake.lock revision of nixpkgs so it only
        changes when the flake is updated.
      '';
    };
  };

  options.cakeos.claude.mcp = {
    enable = lib.mkEnableOption "hecate-mcp as a Claude Code MCP server (`claude mcp add hecate`)";
    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "The package with the hecate-mcp binary. Required when enabled.";
    };
    allow = lib.mkOption {
      type = lib.types.listOf (
        lib.types.enum [
          "windows"
          "tint"
          "notify"
          "all"
        ]
      );
      default = [ "tint" ];
      description = ''
        What hecate-mcp may change (`allow` in ~/.config/hecate/mcp.toml). Without an
        entry it only looks: windows, workspaces, notifications, screenshots.
      '';
    };
    screenshots = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Offer Claude the screenshot tool.";
    };
  };

  options.cakeos.claude.shell.enable = lib.mkEnableOption ''
    the hecate shell's own Claude switch (`claude.enable` in its settings): the bridge,
    sessions panel, ask panel and widgets. The shell keeps that setting itself, so it is
    only turned on while the key is missing and left alone after that
  '';

  config = lib.mkMerge [
    {
      assertions = lib.optional cfg.enable {
        assertion = cfg.script != null;
        message = "cakeos.claude.hooks.script must be set when the Claude hooks are enabled.";
      };

      home.packages = lib.mkIf cfg.enable [ pkgs.jq ];

      # Runs when enabled, and once more after disabling to take our entries back
      # out (the marker file means we installed some).
      home.activation.claudeHooks = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        if cfg.enable then "run ${merge}" else "[ ! -e ${lib.escapeShellArg stateFile} ] || run ${merge}"
      );
    }

    (lib.mkIf cli.enable {
      home.packages = [ cli.package ];
    })

    (lib.mkIf mcp.enable {
      assertions = [
        {
          assertion = mcp.package != null;
          message = "cakeos.claude.mcp.package must be set when hecate-mcp is enabled.";
        }
      ];

      home.packages = lib.optional (mcp.package != null) mcp.package;

      xdg.configFile."hecate/mcp.toml".source = tomlFormat.generate "hecate-mcp.toml" {
        inherit (mcp) allow screenshots;
      };

      # `claude mcp add` writes ~/.claude.json, which belongs to Claude Code, so
      # register once (user scope) and skip while the entry exists.
      home.activation.claudeMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if ! ${lib.getExe cli.package} mcp get hecate >/dev/null 2>&1; then
            run ${lib.getExe cli.package} mcp add --scope user hecate -- ${lib.getExe' mcp.package "hecate-mcp"} || true
        fi
      '';
    })

    (lib.mkIf shell.enable {
      home.activation.claudeShellSwitch = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        cfg=${lib.escapeShellArg shellConfig}
        jq=${lib.getExe pkgs.jq}
        mkdir -p "$(dirname "$cfg")"
        [ -e "$cfg" ] || echo '{}' > "$cfg"
        if "$jq" -e . "$cfg" >/dev/null 2>&1 \
            && [ "$("$jq" '.claude.enable // "unset"' "$cfg")" = '"unset"' ]; then
            tmp=$(mktemp)
            "$jq" '.claude.enable = true' "$cfg" > "$tmp" && cat "$tmp" > "$cfg"
            rm -f "$tmp"
        fi
      '';
    })
  ];
}
