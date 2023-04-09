{ config, pkgs, ... }: {
  home.programs.tmux = {
    enable = true;
    plugins = with pkgs; [
      tmuxPlugins.continuum
      tmuxPlugins.sensible
      tmuxPlugins.yank
      tmuxPlugins.open
      tmuxPlugins.resurrect
      tmuxPlugins.copycat
    ];
    extraConfig = ''
      #add border 
      set-option -g pane-active-border-style "bg=colour208"
      set-option -ag pane-active-border-style "fg=black"

      #resize panes
      bind down resize-pane -D 40
      bind up resize-pane -U 40
      bind left resize-pane -U 10
      bind right resize-pane -D 10

      # Smart pane switching with awareness of vim splits
      is_vim='echo "#{pane_current_command}" | grep -iqE "(^|\/)g?(view|n?vim?)(diff)?$"'
      bind -n C-h if-shell "$is_vim" "send-keys C-h" "select-pane -L"
      bind -n C-j if-shell "$is_vim" "send-keys C-j" "select-pane -D"
      bind -n C-k if-shell "$is_vim" "send-keys C-k" "select-pane -U"
      bind -n C-l if-shell "$is_vim" "send-keys C-l" "select-pane -R"

      # vi key navigation
      setw -g mode-keys vi
      bind-key -T copy-mode-vi 'v' send -X begin-selection
      bind-key -T copy-mode-vi 'y' send -X copy-selection

      set -g @continuum-restore 'on'
      	
      #open new panes at current path
      bind '%' split-window -h -c '#{pane_current_path}'  # Split panes horizontal
      bind '"' split-window -v -c '#{pane_current_path}'  # Split panes vertically
      bind 'c' run-shell "tmux new-window -c '~'; tmux split-window -h -c '~'; tmux select-pane -R"
    '';
  };

  #home.file.".tmux.conf".source = ./.tmux.conf;
}
