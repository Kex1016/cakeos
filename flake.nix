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
    # Neovim (CakeVim, modules/home/editor/cakevim.nix). git+https: the same over the
    # GitHub API-free git transport as hecate.
    nvf = {
      url = "git+https://github.com/notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
    # Affinity v3 under Wine (modules/home/apps/affinity.nix, behind cakeos.affinity.enable).
    # Only its overlay is used, which builds against our nixpkgs.
    affinity-nix = {
      url = "github:mrshmllow/affinity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    # Pinned to the last revision that built: from 3.6.1 on, its bun-deps
    # fixed-output derivation hashes differently on different machines
    # (SteamClientHomebrew/Millennium#934). Back to `next` once that is fixed.
    millennium.url = "github:SteamClientHomebrew/Millennium/e5b683318ac458fab86317e1b3ffcd0aea39d3ff?dir=packages/nix";
    # The hecate compositor and its bundled shell (modules/desktops/hecate).
    # git+https rather than github: so a private repo is fetched with git's own
    # credentials (the github: tarball fetcher is anonymous and gets a 404).
    # Build against a local checkout instead with ./hecate-vm.sh.
    hecate = {
      url = "github:Kex1016/wl-hex";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
    # hecate's login screen (the shell's lock screen as a greetd greeter). It runs the
    # same hecate and shell as the session, so it follows that input.
    # Build against a local checkout with HECATE_GREETD_SRC=... ./build-vm.sh hecate.
    hecate-greetd = {
      url = "github:Kex1016/hecate-greetd";
      inputs.hecate.follows = "hecate";
    };
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
            # A file Home Manager would replace is moved to <file>.bak-<timestamp>. With
            # a fixed `.bak`, an app that keeps rewriting a managed file (VSCodium's
            # settings.json) fails the second activation: the old .bak is in the way.
            backupCommand = "${pkgs.writeShellScript "hm-backup" ''
              ${pkgs.coreutils}/bin/mv -- "$1" "$1.bak-$(${pkgs.coreutils}/bin/date +%Y%m%d-%H%M%S)"
            ''}";
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

      # The desktop switcher, runnable on any CakeOS install, however old:
      #   nix run 'github:Kex1016/cakeos?ref=<branch>#cakeos-wm' -- --branch <branch>
      packages.${system} = {
        cakeos-wm =
          pkgs.runCommand "cakeos-wm"
            {
              nativeBuildInputs = [ pkgs.makeWrapper ];
              meta.mainProgram = "cakeos-wm";
            }
            ''
              install -Dm755 ${./scripts/cakeos-wm} $out/libexec/cakeos-wm
              substituteInPlace $out/libexec/cakeos-wm \
                --replace-fail "#!/usr/bin/env nu" "#!${pkgs.nushell}/bin/nu" \
                --replace-fail "@cakeosSource@" "${self}"
              makeWrapper $out/libexec/cakeos-wm $out/bin/cakeos-wm \
                --prefix PATH : ${
                  lib.makeBinPath [
                    pkgs.git
                    pkgs.rsync
                    pkgs.dconf
                    pkgs.dbus
                  ]
                }
            '';

        # The updater every install runs (its scripts/update-cakeos hands over to this), so
        # where updates come from and how they're applied is always the latest CakeOS's call.
        update-cakeos =
          pkgs.runCommand "update-cakeos"
            {
              nativeBuildInputs = [ pkgs.makeWrapper ];
              meta.mainProgram = "update-cakeos";
            }
            ''
              install -Dm755 ${./scripts/update-cakeos} $out/libexec/update-cakeos
              substituteInPlace $out/libexec/update-cakeos \
                --replace-fail "#!/usr/bin/env nu" "#!${pkgs.nushell}/bin/nu"
              makeWrapper $out/libexec/update-cakeos $out/bin/update-cakeos \
                --set CAKEOS_UPDATER_LATEST 1 \
                --prefix PATH : ${
                  lib.makeBinPath [
                    pkgs.git
                    pkgs.rsync
                  ]
                }
            '';
      };

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
