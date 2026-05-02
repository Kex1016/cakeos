{ ... }:

{
  programs.kitty = {
    enable = true;
    settings = {
      cursor_trail = 1;
      shell = "fish";
      editor = "nvim";
      window_padding_width = 5;
    };
    shellIntegration.enableFishIntegration = true;
  };
}
