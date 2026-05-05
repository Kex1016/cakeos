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
    kwin-effects-glass = {
      url = "github:4v3ngR/kwin-effects-glass";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    millennium.url = "github:SteamClientHomebrew/Millennium?dir=packages/nix";
    glass.url = "github:4v3ngR/Glass";
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
    in
    {
      nixosConfigurations = {
        universe = lib.nixosSystem {
          inherit system pkgs specialArgs;
          modules = commonSystemModules ++ [
            ./systems/universe/configuration.nix
            {
              home-manager.users.majo = import ./systems/universe/home.nix;
            }
          ];
        };

        tarot = lib.nixosSystem {
          inherit system pkgs specialArgs;
          modules = commonSystemModules ++ [
            ./systems/tarot/configuration.nix
            {
              home-manager.users.cakeos = import ./systems/tarot/home.nix;
            }
          ];
        };

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
