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
  ];

  # Neovim
  programs.nvf = {
    enable = true;

    settings = {
      vim.viAlias = true;
      vim.vimAlias = true;

      vim.lsp = {
        enable = true;
      };

      vim.languages = {
        rust = {
          enable = true;
        };
        nix = {
          enable = true;
        };
        sql = {
          enable = true;
        };
        clang = {
          enable = true;
        };
        ts = {
          enable = true;
        };
        python = {
          enable = true;
        };
        markdown = {
          enable = true;
        };
        html = {
          enable = true;
        };
        lua = {
          enable = true;
        };
        php = {
          enable = true;
        };
      };
    };
  };
}
