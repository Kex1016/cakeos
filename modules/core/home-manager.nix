# home-manager is wired into universe and tarot, never into the installer.
#
# `extraSpecialArgs` and `sharedModules` are still here in their pre-migration
# form; they are dismantled once the home-manager modules become dendritic and
# reach `inputs` by lexical closure instead.
{ inputs, ... }:
{
  flake.modules.nixos.base = {
    imports = [ inputs.home-manager.nixosModules.home-manager ];

    home-manager = {
      extraSpecialArgs = { inherit inputs; };
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "bak";
      sharedModules = [
        inputs.nix-flatpak.homeManagerModules.nix-flatpak
        inputs.zen-browser.homeModules.beta
        inputs.spicetify-nix.homeManagerModules.default
      ];
    };
  };
}
