{
  lib,
  osConfig,
  inputs,
  ...
}:

# Vesktop in haiiro: hecate's fixed Vencord theme, and Rosé Pine for code blocks.
let
  vesktop = "${inputs.hecate}/nix/haiiro/vesktop";
in
{
  config =
    lib.mkIf
      (osConfig.cakeos.desktop == "hecate" && builtins.elem "communication" osConfig.cakeos.groups)
      {
        programs.vesktop.vencord = {
          themes.haiiro = builtins.readFile "${vesktop}/haiiro.theme.css";
          settings = {
            enabledThemes = [ "haiiro.css" ];
            plugins.ShikiCodeblocks.theme = import "${vesktop}/shiki.nix";
          };
        };
      };
}
