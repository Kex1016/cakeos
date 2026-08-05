# NOT part of any aggregate, so no host gets it -- exactly as today, where this
# module was imported by nothing. It keeps its own name so it stays visible to
# `nix flake show` and can be opted into by adding it to a host's imports.
{
  flake.modules.nixos.ananicy =
    { pkgs, ... }:
    {
      services.ananicy = {
        enable = true;
        package = pkgs.ananicy-cpp;
        rulesProvider = pkgs.ananicy-rules-cachyos;
      };
    };
}
