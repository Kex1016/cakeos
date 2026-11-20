# The haiiro palette (Rosé Pine, main) as plain Nix, for everything that themes
# itself outside the hecate shell: the boot menus, the installer's console.
# Names are the haiiro design system's colour tokens without the `color-` prefix.
{
  base = "#191724"; # the night sky
  surface = "#1f1d2e"; # window fill
  overlay = "#26233a"; # raised layers, the blob halo
  muted = "#6e6a86"; # c1: labels, quiet info
  subtle = "#908caa"; # secondary text that must stay readable at 16px
  text = "#e0def4"; # body text
  love = "#eb6f92"; # c2: the @ of a prompt, critical
  gold = "#f6c177"; # c3: commands, "needs you"
  rose = "#ebbcba"; # c4: narration, the » arrow
  pine = "#31748f"; # c5: the window frame
  foam = "#9ccfd8"; # c6: paths, headings in windows
  iris = "#c4a7e7"; # c7: files, media
  highlight_low = "#21202e";
  highlight_med = "#403d52"; # the blob core
  highlight_high = "#524f67";
}
