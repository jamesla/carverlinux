{ pkgs, unstable }:
let
  herdr = "${unstable.herdr}/bin/herdr";
  jq = "${pkgs.jq}/bin/jq";

  # Pass the key through to vim when it's focused, otherwise move pane focus.
  navigate = pkgs.writeShellScript "herdr-navigate" ''
    direction="$1"
    key="$2"
    pane="$HERDR_ACTIVE_PANE_ID"
    is_vim='[.result.process_info.foreground_processes[].argv[0] // "" | split("/") | last] | any(test("^g?(view|n?vim?)(diff)?$"))'
    if ${herdr} pane process-info --pane "$pane" | ${jq} -e "$is_vim" > /dev/null; then
      ${herdr} pane send-keys "$pane" "ctrl+$key"
    else
      ${herdr} pane focus --pane "$pane" --direction "$direction"
    fi
  '';

  # New tab in ~, split side by side, focus the right pane.
  newTab = pkgs.writeShellScript "herdr-new-tab" ''
    left=$(${herdr} tab create --workspace "$HERDR_ACTIVE_WORKSPACE_ID" --cwd "$HOME" --focus | ${jq} -r '.result.root_pane.pane_id')
    ${herdr} pane split --pane "$left" --direction right --cwd "$HOME" > /dev/null
    ${herdr} pane focus --pane "$left" --direction right > /dev/null
  '';

  # Runs on workspace.created: nvim on the left, claude on the right. Only
  # acts on a workspace that still has its single initial pane.
  workspaceLayout = pkgs.writeShellScript "herdr-workspace-layout" ''
    panes=$(${herdr} pane list --workspace "$HERDR_WORKSPACE_ID" | ${jq} -r '.result.panes[].pane_id')
    if [ "$(printf '%s\n' "$panes" | grep -c .)" -ne 1 ]; then
      exit 0
    fi
    left="$panes"
    ${herdr} pane run "$left" nvim > /dev/null
    right=$(${herdr} pane split --pane "$left" --direction right --cwd "$HOME" | ${jq} -r '.result.pane.pane_id')
    ${herdr} pane run "$right" claude > /dev/null
    ${herdr} pane focus --pane "$left" --direction right > /dev/null
  '';

  workspacePlugin = pkgs.runCommand "herdr-workspace-layout-plugin" { } ''
    mkdir -p $out
    cp ${workspaceLayout} $out/layout.sh
    cat > $out/herdr-plugin.toml <<EOF
    id = "local.workspace-layout"
    name = "Workspace Layout"
    version = "0.1.0"
    min_herdr_version = "0.7.0"
    description = "Open new workspaces with nvim and claude side by side"
    platforms = ["linux"]

    [[events]]
    on = "workspace.created"
    command = ["$out/layout.sh"]
    EOF
  '';

  resize = direction: amount:
    "${herdr} pane resize --pane $HERDR_ACTIVE_PANE_ID --direction ${direction} --amount ${amount}";

  shellCommand = key: command: {
    inherit key command;
    type = "shell";
  };

  settings = {
    onboarding = false;

    theme = {
      name = "dracula";
      custom.accent = "#ff8700";
    };

    terminal.new_cwd = "follow";

    ui = {
      mouse_capture = false;
      tab_bar_position = "bottom";
    };

    experimental.pane_history = true;

    keys = {
      prefix = "ctrl+b";
      split_vertical = "prefix+%";
      split_horizontal = "prefix+\"";
      new_tab = "";
      command = [
        (shellCommand "prefix+c" "${newTab}")
        (shellCommand "prefix+up" (resize "up" "0.4"))
        (shellCommand "prefix+down" (resize "down" "0.4"))
        (shellCommand "prefix+left" (resize "up" "0.1"))
        (shellCommand "prefix+right" (resize "down" "0.1"))
        (shellCommand "ctrl+h" "${navigate} left h")
        (shellCommand "ctrl+j" "${navigate} down j")
        (shellCommand "ctrl+k" "${navigate} up k")
        (shellCommand "ctrl+l" "${navigate} right l")
      ];
    };
  };
in
{
  home.packages = [ unstable.herdr ];

  xdg.configFile."herdr/config.toml".source =
    (pkgs.formats.toml { }).generate "herdr-config.toml" settings;

  # Herdr keeps linked plugins in its own user-global state, so re-link on every
  # switch: the store path changes whenever the script does.
  home.activation.herdrWorkspaceLayout = ''
    ${herdr} plugin unlink local.workspace-layout > /dev/null 2>&1 || true
    ${herdr} plugin link ${workspacePlugin} > /dev/null 2>&1 || true
  '';
}
