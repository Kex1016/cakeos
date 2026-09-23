{ pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    bun
    dust
    duf
    nixfmt
    pipes
    wget
    git
    psmisc
    nix-tree
    wl-clipboard
    brightnessctl
    playerctl
    trash-cli
    efibootmgr
    jq
    tokei
    ffmpeg
    imagemagick # used by scripts/compress-media
    gettext
    rustup
    clang
    android-tools
    scrcpy
    _7zz
    #nix-alien
    gpu-screen-recorder
    docker-compose
    inputs.nvf.packages.${pkgs.stdenv.hostPlatform.system}.default
    zenity
  ];

  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableNushellIntegration = true;
    };
    git = {
      enable = true;
      settings = {
        user = {
          name = "cakes";
          email = "cakes@haiiro.moe";
        };
      };
    };
    btop = {
      enable = true;
      settings = {
        theme_background = false;
        color_theme = "Default";
      };
    };
    bat = {
      enable = true;
      extraPackages = with pkgs.bat-extras; [
        batdiff
        batman
        batgrep
        batwatch
      ];
    };
    eza = {
      enable = true;
      enableNushellIntegration = true;
      colors = "auto";
      icons = "auto";
      git = true;
      extraOptions = [
        "--group-directories-first"
        "--header"
      ];
    };
    ripgrep.enable = true;
    zoxide = {
      enable = true;
      enableNushellIntegration = true;
      options = [ "--cmd cd" ];
    };
    fastfetch = {
      enable = true;
      settings = {
        logo = {
          source = "nixos_small";
          padding = {
            right = 1;
          };
        };
        display = {
          size = {
            ndigits = 0;
            maxPrefix = "MB";
          };
          color = "blue";
          separator = "  ";
          key.type = "icon";
        };
        modules = [
          {
            type = "title";
            color = {
              user = "green";
              at = "red";
              host = "blue";
            };
          }
          "os"
          "kernel"
          "memory"
          "packages"
          "uptime"
          {
            type = "colors";
            key = "Colors";
            block = {
              range = [
                1
                6
              ];
            };
          }
        ];
      };
    };
  };
}
