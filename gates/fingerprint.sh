# shellcheck shell=bash
# The installer "fingerprint": the options whose values must survive the
# migration unchanged, independent of where files live in the tree.
#
# Sourced by both gates.sh (which evaluates it per phase) and run-matrix.sh
# (which records it once against main), so the two sides of the comparison can
# never drift apart.
#
# Why not compare drvPaths? The installer sets
#     environment.etc."cakeos".source = self
# which makes its derivation hash depend on every byte of the repository. Any
# file rename moves it -- and this migration renames nearly everything. The
# fingerprint captures what actually matters instead.

INSTALLER_FP_ATTR='.#nixosConfigurations.installer.config'

INSTALLER_FP_APPLY='c: {
  packages     = builtins.sort (a: b: a < b) (map (p: p.name or "?") c.environment.systemPackages);
  autologin    = c.services.getty.autologinUser;
  distroName   = c.system.nixos.distroName;
  distroId     = c.system.nixos.distroId;
  hostName     = c.networking.hostName;
  stateVersion = c.system.stateVersion;
  timeZone     = c.time.timeZone;
  locale       = c.i18n.defaultLocale;
  features     = c.nix.settings.experimental-features;
  trustedUsers = c.nix.settings.trusted-users;
  loginShell   = c.programs.bash.loginShellInit;
}'
