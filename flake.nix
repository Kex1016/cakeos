{
  description = "The main OS flake for CakeOS.";

  inputs = {
    # Utils
    systems.url = "github:nix-systems/x86_64-linux";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };

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

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }@inputs:
    let
      system = "x86_64-linux";

      lib = nixpkgs.lib;
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          inputs.nur.overlays.default
          inputs.nix-cachyos-kernel.overlays.pinned
          inputs.millennium.overlays.default
          inputs.affinity-nix.overlays.default
        ];
      };

      specialArgs = {
        inherit inputs;
      };

      commonHomeModules = [
        inputs.nix-flatpak.homeManagerModules.nix-flatpak
        inputs.zen-browser.homeModules.beta
        (inputs.spicetify-nix.homeManagerModules.default)
      ];

      commonSystemModules = [
        inputs.disko.nixosModules.disko
        inputs.home-manager.nixosModules.home-manager
        (inputs.spicetify-nix.nixosModules.spicetify)
        ./system.nix
        {
          home-manager = {
            extraSpecialArgs = specialArgs;
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "bak";
            sharedModules = commonHomeModules;
          };
        }
      ];
      desktops = import ./modules/desktops/list.nix;

      # One generic host. Which desktop, which package groups, the username and
      # so on all come from gen/<genName>.nix, which the installer writes.
      mkHost =
        genName:
        lib.nixosSystem {
          inherit system pkgs;
          specialArgs = specialArgs // {
            inherit genName;
          };
          modules = commonSystemModules ++ [ ./systems/cakeos/configuration.nix ];
        };
    in
    {
      # The installer reads this to build its desktop menu.
      cakeosDesktops = desktops;

      nixosConfigurations = {
        cakeos = mkHost "cakeos";

        # Machines installed before the single-config layout still have
        # gen/universe.nix or gen/tarot.nix on disk; keep their flake attrs
        # resolvable so `update-cakeos` does not break on them.
        universe = mkHost "universe";
        tarot = mkHost "tarot";

        installer = lib.nixosSystem {
          inherit system pkgs specialArgs;
          modules = [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-base.nix"
            inputs.disko.nixosModules.disko
            ./systems/installer/configuration.nix
          ];
        };
      };
    };
}
