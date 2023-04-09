{ config, pkgs, ... }:

let
  nvchad = pkgs.callPackage ./packages/neovim/nvchad.nix {};
in {
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "vagrant";
  home.homeDirectory = "/home/vagrant";

  home.packages = [
    nvchad
  ];

  programs.git = {
    enable = true;
    userName = "jamesla";
    userEmail = "jamesgmccallum@gmail.com";
  };

  programs.chromium = {
    enable = true;
    extensions = [
      "dbepggeogbaibhgnhhndojpepiihcmeb" # vimium
    ];
  };

  programs.tmux = {
    enable = true;
    plugins = with pkgs; [
      tmuxPlugins.sensible
      tmuxPlugins.yank
      tmuxPlugins.open
      {
        plugin = tmuxPlugins.resurrect;
        extraConfig = ''
          set -g @resurrect-strategy-nvim 'session'
          set -g @resurrect-processes '~nvim'
          set -g @resurrect-capture-pane-contents 'on'
        '';
      }
      {
        plugin = tmuxPlugins.continuum;
        extraConfig = ''
          set -g @continuum-boot 'on'
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '1';
          set -g status-right 'Continuum status: #{continuum_status}'
        '';
      }
    ];
    extraConfig = ''
      set-option -g pane-active-border-style "bg=colour208"
      set-option -ag pane-active-border-style "fg=black"
      bind down resize-pane -D 40
      bind up resize-pane -U 40
      bind left resize-pane -U 10
      bind right resize-pane -D 10
      is_vim='echo "#{pane_current_command}" | grep -iqE "(^|\/)g?(view|n?vim?)(diff)?$"'
      bind -n C-h if-shell "$is_vim" "send-keys C-h" "select-pane -L"
      bind -n C-j if-shell "$is_vim" "send-keys C-j" "select-pane -D"
      bind -n C-k if-shell "$is_vim" "send-keys C-k" "select-pane -U"
      bind -n C-l if-shell "$is_vim" "send-keys C-l" "select-pane -R"
      setw -g mode-keys vi
      bind-key -T copy-mode-vi 'v' send -X begin-selection
      bind-key -T copy-mode-vi 'y' send -X copy-selection
      set -g @continuum-restore 'on'
      bind '%' split-window -h -c '#{pane_current_path}'  # Split panes horizontal
      bind '"' split-window -v -c '#{pane_current_path}'  # Split panes vertically
      bind 'c' run-shell "tmux new-window -c '~'; tmux split-window -h -c '~'; tmux select-pane -R"
    '';
  };

  xdg.configFile.nvim = {
    source = nvchad;
  };

  home.stateVersion = "22.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
