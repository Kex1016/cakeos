{
  lib,
  pkgs,
  osConfig,
  inputs,
  ...
}:

# Cider in haiiro: hecate's fixed Cider theme (theme.yml and main.css).
# Cider is a Flatpak, and its sandbox cannot follow a symlink into /nix/store, so
# home.file would leave it an empty theme. The two files are copied instead, and
# only when they differ. Turning the stylesheet on (Settings, Extensions, Haiiro)
# and the Cider settings the theme needs (nix/haiiro/cider/settings.json in
# hecate) stay in Cider's own config, which Cider rewrites itself.
let
  cider = "${inputs.hecate}/nix/haiiro/cider";
in
{
  config =
    lib.mkIf (osConfig.cakeos.desktop == "hecate" && builtins.elem "flatpak" osConfig.cakeos.groups)
      {
        home.activation.haiiroCider = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          haiiroCiderDir="$HOME/.var/app/sh.cider.Cider/config/sh.cider.genten/themes/haiiro"
          run ${pkgs.coreutils}/bin/mkdir -p "$haiiroCiderDir"
          for f in theme.yml main.css; do
            if ! ${pkgs.diffutils}/bin/cmp -s "${cider}/$f" "$haiiroCiderDir/$f"; then
              run ${pkgs.coreutils}/bin/install -m 644 "${cider}/$f" "$haiiroCiderDir/$f"
            fi
          done
          unset haiiroCiderDir
        '';
      };
}
