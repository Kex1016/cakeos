{
  lib,
  pkgs,
  inputs,
  osConfig,
  ...
}:

lib.mkIf (builtins.elem "development" osConfig.cakeos.groups) {
  home.packages = with pkgs; [
    ripgrep
    fd
    fzf

    lua-language-server
    nil
    nixpkgs-fmt

    nodejs

    jetbrains.idea
    gitkraken
    inputs.nvf.packages.${pkgs.stdenv.hostPlatform.system}.default
    biome
    claude-code
    claude-monitor
    claude-mergetool
  ];

  programs.vscodium = {
    enable = true;
    package = pkgs.vscodium;
    profiles.default.extensions = with pkgs.vscode-extensions; [
      mkhl.direnv
      jnoortheen.nix-ide
      leonardssh.vscord
      editorconfig.editorconfig
      arrterian.nix-env-selector
      mkhl.shfmt
      bradlc.vscode-tailwindcss
      ban.spellright
      christian-kohler.npm-intellisense
      christian-kohler.path-intellisense
      dbaeumer.vscode-eslint
      eg2.vscode-npm-script
      esbenp.prettier-vscode
      humao.rest-client
      biomejs.biome
      gruntfuggly.todo-tree
      vscjava.vscode-maven
      vscjava.vscode-java-debug
      vscjava.vscode-gradle
      vscjava.vscode-java-test
      vscjava.vscode-java-dependency
      redhat.java
      ms-vscode.live-server
      rust-lang.rust-analyzer
      tamasfe.even-better-toml
      fill-labs.dependi
      sumneko.lua
      humao.rest-client
    ];
    profiles.default.userSettings = {
      "editor.fontFamily" = "'RobotoMono Nerd Font Mono', 'Droid Sans Mono', 'monospace', monospace";
      "editor.fontLigatures" = true;
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "nil";
      "nix.serverSettings" = {
        "nil" = {
          "formatting" = {
            "command" = [ "nixfmt" ];
          };
        };
      };
      "[javascript][typescript][json][typescriptreact][css][html]" = {
        "editor.defaultFormatter" = "biomejs.biome";
      };
      "git.autofetch" = true;
      "diffEditor.ignoreTrimWhitespace" = false;
      "json.schemaDownload.trustedDomains" = {
        "https://schemastore.azurewebsites.net/" = true;
        "https://raw.githubusercontent.com/microsoft/vscode/" = true;
        "https://raw.githubusercontent.com/devcontainers/spec/" = true;
        "https://www.schemastore.org/" = true;
        "https://json.schemastore.org/" = true;
        "https://json-schema.org/" = true;
        "https://developer.microsoft.com/json-schemas/" = true;
        "https://biomejs.dev" = true;
      };
    };
  };
}
