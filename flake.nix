{
  description = "The main OS flake for CakeOS.";

  inputs = {
    # Flake framework
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    # OS
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Packages
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvf = {
      url = "github:mana-byte/nvf-configuration";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    millennium.url = "github:SteamClientHomebrew/Millennium/next?dir=packages/nix";
    affinity-nix.url = "github:mrshmllow/affinity-nix";
  };

  # This file is an entry point and nothing else. Every other .nix file under
  # modules/ is a flake-parts module and is imported automatically, so adding a
  # feature never means editing this file.
  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        # Declares `flake.modules.<class>.<name>` as
        # lazyAttrsOf (lazyAttrsOf deferredModule).
        #
        # This is NOT part of flake-parts core. Without it `flake.modules` falls
        # through to the freeform `flake` type, which is `types.unique` and so
        # accepts exactly one definition -- meaning the second file to define
        # `flake.modules` fails with an error that reads like a typo report.
        inputs.flake-parts.flakeModules.modules

        # Recursively imports every *.nix under ./modules whose path contains no
        # "/_" component. That underscore rule is what keeps the not-yet-migrated
        # modules/_system and modules/_home trees -- which are NixOS and
        # home-manager modules, not flake-parts modules -- out of this evaluation.
        (inputs.import-tree ./modules)
      ];
    };
}
