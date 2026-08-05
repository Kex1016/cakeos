# NOT part of any aggregate. This was commented out of universe's import list;
# declaring it under its own name is the dendritic equivalent of that, without
# leaving commented-out code behind.
{
  flake.modules.nixos.mongo = {
    services.mongodb = {
      enable = true;
      user = "majo";
    };
  };
}
