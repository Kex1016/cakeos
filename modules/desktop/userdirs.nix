{ ... }:
{
  flake.modules.homeManager.base =
    { ... }:
    {
      xdg.userDirs = {
        enable = true;
        createDirectories = true;
      };
    };
}
