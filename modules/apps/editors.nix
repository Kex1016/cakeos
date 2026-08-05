{ ... }:
{
  flake.modules.homeManager.workstation =
    { pkgs, ... }:
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
      ];
    };
}
