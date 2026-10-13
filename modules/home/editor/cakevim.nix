# CakeVim: Neovim through upstream nvf, set up after NvChad (its look, plugins and key
# bindings) with CakeOS branding. `nvim`, `vim` and `vi` all start it.
{ inputs, ... }:

let
  # "CakeVim" in ANSI Shadow, for the start screen.
  banner = [
    " ██████╗ █████╗ ██╗  ██╗███████╗██╗   ██╗██╗███╗   ███╗"
    "██╔════╝██╔══██╗██║ ██╔╝██╔════╝██║   ██║██║████╗ ████║"
    "██║     ███████║█████╔╝ █████╗  ██║   ██║██║██╔████╔██║"
    "██║     ██╔══██║██╔═██╗ ██╔══╝  ╚██╗ ██╔╝██║██║╚██╔╝██║"
    "╚██████╗██║  ██║██║  ██╗███████╗ ╚████╔╝ ██║██║ ╚═╝ ██║"
    " ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝  ╚═══╝  ╚═╝╚═╝     ╚═╝"
  ];

  # Start screen entries, like NvChad's nvdash.
  button = icon: desc: key: action: {
    inherit
      icon
      desc
      key
      action
      ;
    icon_hl = "Title";
    desc_hl = "String";
    key_hl = "Number";
    key_format = " %s";
  };

  # A key binding; `lua = true` makes `action` Lua.
  map = mode: key: action: desc: {
    inherit
      mode
      key
      action
      desc
      ;
    silent = true;
  };
  lua =
    mode: key: action: desc:
    (map mode key action desc) // { lua = true; };
in
{
  imports = [ inputs.nvf.homeManagerModules.default ];

  programs.nvf = {
    enable = true;
    settings.vim = {
      viAlias = true;
      vimAlias = true;

      # --- Look ---------------------------------------------------------------------
      # NvChad's default theme is One Dark.
      theme = {
        enable = true;
        name = "onedark";
        style = "dark";
      };
      statusline.lualine = {
        enable = true;
        # One statusline for all windows, like NvChad.
        setupOpts.options.globalstatus = true;
      };
      tabline.nvimBufferline = {
        enable = true;
        mappings = {
          cycleNext = "<Tab>";
          cyclePrevious = "<S-Tab>";
          closeCurrent = "<leader>x";
        };
      };
      visuals = {
        nvim-web-devicons.enable = true;
        indent-blankline.enable = true;
        fidget-nvim.enable = true;
      };
      ui = {
        borders.enable = true;
        colorizer.enable = true;
      };
      notify.nvim-notify.enable = true;

      dashboard.dashboard-nvim = {
        enable = true;
        setupOpts = {
          theme = "doom";
          config = {
            header = [
              ""
              ""
              ""
            ]
            ++ banner
            ++ [
              ""
              "      CakeOS's own Neovim"
              ""
              ""
            ];
            center = [
              (button "  " "Find File" "f" "Telescope find_files")
              (button "󰈚  " "Recent Files" "r" "Telescope oldfiles")
              (button "󰈭  " "Find Word" "w" "Telescope live_grep")
              (button "  " "New File" "n" "enew")
              (button "  " "File Tree" "e" "NvimTreeToggle")
              (button "  " "Themes" "t" "Telescope colorscheme")
              (button "  " "Mappings" "m" "WhichKey")
              (button "󰅚  " "Quit" "q" "qa")
            ];
            footer = [
              ""
              "🍰 CakeVim"
            ];
          };
        };
      };

      # --- Editing ------------------------------------------------------------------
      globals = {
        mapleader = " ";
        maplocalleader = " ";
      };
      lineNumberMode = "number";
      searchCase = "smart";
      undoFile.enable = true;
      clipboard = {
        enable = true;
        registers = "unnamedplus";
        providers.wl-copy.enable = true;
      };
      # NvChad's options.
      options = {
        title = true;
        titlestring = "CakeVim — %t";
        laststatus = 3;
        showmode = false;
        cursorline = true;
        cursorlineopt = "number";
        expandtab = true;
        shiftwidth = 2;
        tabstop = 2;
        softtabstop = 2;
        smartindent = true;
        mouse = "a";
        numberwidth = 2;
        ruler = false;
        signcolumn = "yes";
        splitbelow = true;
        splitright = true;
        timeoutlen = 400;
        updatetime = 250;
      };

      autopairs.nvim-autopairs.enable = true;
      comments.comment-nvim.enable = true;
      snippets.luasnip.enable = true;
      autocomplete.nvim-cmp.enable = true;
      treesitter.enable = true;

      # --- Tools --------------------------------------------------------------------
      filetree.nvimTree = {
        enable = true;
        mappings = {
          toggle = "<C-n>";
          focus = "<leader>e";
        };
      };
      telescope = {
        enable = true;
        mappings = {
          findFiles = "<leader>ff";
          liveGrep = "<leader>fw";
          buffers = "<leader>fb";
          helpTags = "<leader>fh";
          gitCommits = "<leader>cm";
        };
      };
      binds = {
        whichKey.enable = true;
        cheatsheet.enable = true;
      };
      git = {
        enable = true;
        gitsigns.enable = true;
        gitsigns.codeActions.enable = false;
      };
      terminal.toggleterm.enable = true;

      # --- Languages ----------------------------------------------------------------
      lsp = {
        enable = true;
        formatOnSave = false;
        # NvChad's LSP bindings.
        mappings = {
          goToDeclaration = "gD";
          goToDefinition = "gd";
          hover = "K";
          listImplementations = "gi";
          listReferences = "gr";
          goToType = "<leader>D";
          signatureHelp = "<leader>sh";
          renameSymbol = "<leader>ra";
          codeAction = "<leader>ca";
          format = "<leader>fm";
          openDiagnosticFloat = "<leader>lf";
          nextDiagnostic = "]d";
          previousDiagnostic = "[d";
        };
      };
      languages = {
        enableFormat = true;
        enableTreesitter = true;
        nix.enable = true;
        bash.enable = true;
        lua.enable = true;
        markdown.enable = true;
        python.enable = true;
        rust.enable = true;
        typescript.enable = true;
        css.enable = true;
        html.enable = true;
        json.enable = true;
        toml.enable = true;
        qml.enable = true;
        nu.enable = true;
      };

      # --- NvChad's key bindings ----------------------------------------------------
      keymaps = [
        # Not silent: that would hide the command line being typed.
        ((map "n" ";" ":" "Command mode") // { silent = false; })
        (map "i" "jk" "<Esc>" "Escape insert mode")
        (map [ "n" "i" ] "<C-s>" "<cmd>w<CR>" "Save file")
        (map "n" "<C-c>" "<cmd>%y+<CR>" "Copy whole file")
        (map "n" "<Esc>" "<cmd>noh<CR>" "Clear highlights")
        (map "n" "<C-h>" "<C-w>h" "Window left")
        (map "n" "<C-l>" "<C-w>l" "Window right")
        (map "n" "<C-j>" "<C-w>j" "Window down")
        (map "n" "<C-k>" "<C-w>k" "Window up")
        (map "n" "<leader>n" "<cmd>set nu!<CR>" "Toggle line numbers")
        (map "n" "<leader>rn" "<cmd>set rnu!<CR>" "Toggle relative numbers")
        (map "n" "<leader>b" "<cmd>enew<CR>" "New buffer")
        (map "n" "<leader>ch" "<cmd>Cheatsheet<CR>" "Cheatsheet")
        (map "n" "<leader>th" "<cmd>Telescope colorscheme<CR>" "Themes")
        (map "n" "<leader>fa" "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<CR>"
          "Find all files"
        )
        (map "n" "<leader>fo" "<cmd>Telescope oldfiles<CR>" "Recent files")
        (map "n" "<leader>fz" "<cmd>Telescope current_buffer_fuzzy_find<CR>" "Find in buffer")
        (map "n" "<leader>gt" "<cmd>Telescope git_status<CR>" "Git status")
        (map "n" "<leader>ma" "<cmd>Telescope marks<CR>" "Marks")
        (map "n" "<leader>wK" "<cmd>WhichKey<CR>" "All key bindings")
        (lua "n" "<leader>ds" "vim.diagnostic.setloclist" "Diagnostics list")
        # Comment with leader-/ (Comment.nvim's API; mapping to its gcc would need
        # remap, which nvf's keymaps can't express).
        (lua "n" "<leader>/" "function() require('Comment.api').toggle.linewise.current() end"
          "Toggle comment"
        )
        (map "v" "<leader>/" "<Esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>"
          "Toggle comment"
        )
        # Terminals: Alt-i floating, Alt-h horizontal, Alt-v vertical; Ctrl-x leaves
        # terminal mode.
        (map [ "n" "t" ] "<A-i>" "<cmd>1ToggleTerm direction=float<CR>" "Floating terminal")
        (map [ "n" "t" ] "<A-h>" "<cmd>2ToggleTerm direction=horizontal<CR>" "Horizontal terminal")
        (map [ "n" "t" ] "<A-v>" "<cmd>3ToggleTerm direction=vertical size=60<CR>" "Vertical terminal")
        (map "t" "<C-x>" "<C-\\><C-N>" "Leave terminal mode")
      ];
    };
  };
}
