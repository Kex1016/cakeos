{
  # CakeOS targets exactly one platform. flake-parts wants this declared even
  # when no `perSystem` block exists.
  systems = [ "x86_64-linux" ];
}
