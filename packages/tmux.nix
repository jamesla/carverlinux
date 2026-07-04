{ config, pkgs, ... }:
{
  enable = true;
  plugins = with pkgs; [
    tmuxPlugins.sensible
    tmuxPlugins.yank
    tmuxPlugins.dracula
    tmuxPlugins.open
    tmuxPlugins.resurrect
    {
      plugin = tmuxPlugins.continuum;
      extraConfig = ''
        set -g @continuum-save-interval '1';
        set -g @continuum-restore 'on';
      '';
    }
  ];
  extraConfig = ''
    # st-256color terminfo omits AX, so tmux can't emit ESC[39m/ESC[49m to
    # reset to default fg/bg; dracula's status-bar greens then leak into pane text.
    set -ga terminal-overrides ",st-256color:AX"
    set -as terminal-features ",st-256color:RGB"

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
    bind '%' split-window -h -c '#{pane_current_path}'  # Split panes horizontal
    bind '"' split-window -v -c '#{pane_current_path}'  # Split panes vertically
    bind 'c' run-shell "tmux new-window -c '~'; tmux split-window -h -c '~'; tmux select-pane -R"

    run-shell ${pkgs.tmuxPlugins.yank}/share/tmux-plugins/yank/yank.tmux
  '';
}
