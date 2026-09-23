# The set of available desktop environments, discovered from the directories
# next to this file. Adding a desktop means creating one directory here — it is
# picked up by the option enum, the module imports and the installer's menu
# without any list needing to be edited.
#
# Each <desktop>/ directory must provide:
#   system.nix  NixOS-level config (display manager, session, DE packages)
#   home.nix    home-manager config (theming, terminal, file associations)
#   groups.nix  desktop-specific additions per package group
#   meta.nix    { description = "..."; }  shown in the installer

let
  entries = builtins.readDir ./.;
  isDesktop = name: type: type == "directory" && builtins.pathExists (./. + "/${name}/system.nix");
in
builtins.attrNames (
  builtins.listToAttrs (
    map (n: {
      name = n;
      value = true;
    }) (builtins.filter (n: isDesktop n entries.${n}) (builtins.attrNames entries))
  )
)
