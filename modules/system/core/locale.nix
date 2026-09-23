{ config, lib, ... }:
let
  # "hu+qwerty" -> layout "hu", variant "qwerty"
  layouts = config.cakeos.keyboardLayouts;
  split = l: lib.splitString "+" l;
  layoutNames = map (l: builtins.head (split l)) layouts;
  variantNames = map (
    l:
    let
      p = split l;
    in
    if builtins.length p > 1 then builtins.elemAt p 1 else ""
  ) layouts;
in
{
  time.timeZone = config.cakeos.timeZone;

  services.xserver.xkb = {
    layout = lib.concatStringsSep "," layoutNames;
    variant = lib.concatStringsSep "," variantNames;
  };
  console.useXkbConfig = true;

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "hu_HU.UTF-8";
    LC_IDENTIFICATION = "hu_HU.UTF-8";
    LC_MEASUREMENT = "hu_HU.UTF-8";
    LC_MONETARY = "hu_HU.UTF-8";
    LC_NAME = "hu_HU.UTF-8";
    LC_NUMERIC = "hu_HU.UTF-8";
    LC_PAPER = "hu_HU.UTF-8";
    LC_TELEPHONE = "hu_HU.UTF-8";
    LC_TIME = "hu_HU.UTF-8";
  };
}
