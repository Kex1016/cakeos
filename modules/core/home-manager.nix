# home-manager is wired into universe and tarot, never into the installer.
#
# `sharedModules` is gone: the three third-party home-manager modules are now
# imported by the feature files that actually use them --
#   zen-browser  -> modules/apps/browsers.nix
#   spicetify    -> modules/apps/essentials.nix
#   nix-flatpak  -> modules/apps/flatpak.nix
# so each option declaration travels with its only consumer.
#
# `extraSpecialArgs` is still here purely as a safety net for anything that has
# not yet been converted; it is removed in the cleanup phase.
{ inputs, ... }:
{
  flake.modules.nixos.base = {
    imports = [ inputs.home-manager.nixosModules.home-manager ];

    home-manager = {
      extraSpecialArgs = { inherit inputs; };
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "bak";
    };
  };

  # Everything every home-manager profile on every host gets.
  #
  # home.username and home.homeDirectory are deliberately NOT set. When
  # home-manager runs as a NixOS module it derives both from
  # users.users.<name>, without mkDefault -- which is why the old universe
  # profile needed lib.mkForce to override homeDirectory. Leaving them unset
  # makes these profiles username-agnostic and lets gen/<host>.nix stay the
  # single source of truth for identity.
  flake.modules.homeManager.base = {
    home.stateVersion = "26.05";
  };
}
