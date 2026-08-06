{ pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    ripgrep
    fd
    fzf

    lua-language-server
    nil
    nixpkgs-fmt

    nodejs

    antigravity-fhs
    affinity-v3
    jetbrains.idea
    inputs.nvf.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
