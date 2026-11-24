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

  # Runs on pane.agent_status_changed: turns herdr's agent status transitions
  # into the Claude Code hook events peon-ping expects, so sounds follow
  # herdr's view of every agent instead of Claude Code's own hooks.
  peonSettleSeconds = "2";

  peonHook = pkgs.writeShellScript "herdr-peon-hook" ''
    data=$(printf '%s' "''${HERDR_PLUGIN_EVENT_JSON:-}" | ${jq} -c '.data // .' 2> /dev/null) || exit 0
    pane=$(printf '%s' "$data" | ${jq} -r '.pane_id // empty')
    pane="''${pane:-''${HERDR_PANE_ID:-}}"
    [ -n "$pane" ] || exit 0

    session="herdr-$(printf '%s' "$pane" | tr -c 'A-Za-z0-9_.-' '_')"
    status_file="$HERDR_PLUGIN_STATE_DIR/$session.status"
    # Exists while the agent is mid-turn: from the first "working" until it
    # has stayed finished for ${peonSettleSeconds}s.
    turn_file="$HERDR_PLUGIN_STATE_DIR/$session.turn"

    # A pane that closes, or gains or loses an agent, starts from a clean
    # slate. Closing a whole tab emits no pane.closed, so the next agent
    # detected in a reused pane id is what clears a stale turn.
    case "''${HERDR_PLUGIN_EVENT:-}" in
      pane.closed | pane.agent_detected)
        rm -f "$status_file" "$turn_file"
        exit 0
        ;;
    esac

    status=$(printf '%s' "$data" | ${jq} -r '.agent_status // empty')
    [ -n "$status" ] || exit 0
    mkdir -p "$HERDR_PLUGIN_STATE_DIR"
    previous=$(cut -d' ' -f1 "$status_file" 2> /dev/null)
    stamp="$status $$ $(date +%s%N)"
    printf '%s' "$stamp" > "$status_file"

    case "$status" in
      working)
        # Already mid-turn: resuming after a prompt, or status flicker.
        [ -e "$turn_file" ] && exit 0
        : > "$turn_file"
        event=UserPromptSubmit
        ;;
      idle | done)
        [ -e "$turn_file" ] || exit 0
        # Herdr reads status off the screen and can flicker working -> idle ->
        # working; only a finish that outlasts the settle window counts.
        sleep ${peonSettleSeconds}
        [ "$(cat "$status_file" 2> /dev/null)" = "$stamp" ] || exit 0
        rm -f "$turn_file"
        event=Stop
        ;;
      blocked)
        [ "$previous" = blocked ] && exit 0
        event=PermissionRequest
        ;;
      *)
        # unknown: the agent left the pane.
        rm -f "$turn_file"
        exit 0
        ;;
    esac

    cwd=$("''${HERDR_BIN_PATH:-${herdr}}" agent get "$pane" 2> /dev/null | ${jq} -r '.result.agent.cwd // empty' 2> /dev/null)

    ${jq} -nc --arg event "$event" --arg session "$session" --arg cwd "''${cwd:-$HOME}" \
      '{hook_event_name: $event, session_id: $session, cwd: $cwd, notification_type: "", permission_mode: "", source: "herdr"}' \
      | "$HOME/.openpeon/peon.sh" > /dev/null 2>&1
    exit 0
  '';

  peonPlugin = pkgs.runCommand "herdr-peon-ping-plugin" { } ''
    mkdir -p $out
    cp ${peonHook} $out/peon-hook.sh
    cat > $out/herdr-plugin.toml <<EOF
    id = "local.peon-ping"
    name = "Peon Ping"
    version = "0.1.0"
    min_herdr_version = "0.9.0"
    description = "Play peon-ping sounds when agents change state"
    platforms = ["linux"]

    [[events]]
    on = "pane.agent_status_changed"
    command = ["$out/peon-hook.sh"]

    [[events]]
    on = "pane.agent_detected"
    command = ["$out/peon-hook.sh"]

    [[events]]
    on = "pane.closed"
    command = ["$out/peon-hook.sh"]
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
      # peon-ping plays the agent sounds (see peonPlugin).
      sound.enabled = false;
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
    ${herdr} plugin unlink local.peon-ping > /dev/null 2>&1 || true
    ${herdr} plugin link ${peonPlugin} > /dev/null 2>&1 || true
  '';
}
