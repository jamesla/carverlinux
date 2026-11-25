{ lib, pkgs, unstable }:
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

  # Runs on workspace.created: nvim on the left, claude on the right, both in
  # the workspace's directory. Only acts on a workspace that still has its
  # single initial pane.
  workspaceLayout = pkgs.writeShellScript "herdr-workspace-layout" ''
    panes=$(${herdr} pane list --workspace "$HERDR_WORKSPACE_ID" | ${jq} -c '.result.panes')
    if [ "$(printf '%s' "$panes" | ${jq} 'length')" -ne 1 ]; then
      exit 0
    fi
    left=$(printf '%s' "$panes" | ${jq} -r '.[0].pane_id')
    cwd=$(printf '%s' "$panes" | ${jq} -r '.[0].cwd // empty')
    ${herdr} pane run "$left" nvim > /dev/null
    right=$(${herdr} pane split --pane "$left" --direction right --cwd "''${cwd:-$HOME}" | ${jq} -r '.result.pane.pane_id')
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

  # Plays a random SCV clip from a hardcoded list for each herdr event:
  #   workspace.created       -> peonSounds.start
  #   workspace.closed        -> peonSounds.end
  #   agent status -> blocked -> peonSounds.blocked
  #   agent status -> working -> peonSounds.working
  #   agent status working -> idle -> peonSounds.end
  # Everything else is silent. Clips come from the sc_scv pack peon-ping
  # installs; peon's pause, enabled and volume settings are still honoured.
  peonSounds = {
    start = [ "ReportinForDuty.mp3" "OrdersCapn.mp3" "YesSir.mp3" "GoodToGoSir.mp3" ];
    end = [ "JobsFinished.mp3" ];
    blocked = [ "SomethingsInTheWay.mp3" "CantBuildThere.mp3" ];
    working = [ "Affirmative.mp3" "RogerThat.mp3" "RightAwaySir.mp3" "OrdersReceived.mp3" ];
  };

  peonHook = pkgs.writeShellScript "herdr-peon-hook" ''
    peon_dir="$HOME/.openpeon"
    log="$HERDR_PLUGIN_STATE_DIR/peon-hook.log"
    mkdir -p "$HERDR_PLUGIN_STATE_DIR"
    data=$(printf '%s' "''${HERDR_PLUGIN_EVENT_JSON:-}" | ${jq} -c '.data // .' 2> /dev/null) || exit 0

    # play <clip>...: play one of the given clips at random.
    play() {
      [ -e "$peon_dir/.paused" ] && return 0
      [ "$(${jq} -r '.enabled // true' "$peon_dir/config.json" 2> /dev/null)" = false ] && return 0
      volume=$(${jq} -r '.volume // 0.5' "$peon_dir/config.json" 2> /dev/null)
      shift $((RANDOM % $#))
      ${pkgs.pipewire}/bin/pw-play --volume "$volume" "$peon_dir/packs/sc_scv/sounds/$1" 2>> "$log"
    }

    case "''${HERDR_PLUGIN_EVENT:-}" in
      workspace.created)
        play ${lib.escapeShellArgs peonSounds.start}
        exit 0
        ;;
      workspace.closed)
        play ${lib.escapeShellArgs peonSounds.end}
        exit 0
        ;;
    esac

    pane=$(printf '%s' "$data" | ${jq} -r '.pane_id // empty')
    pane="''${pane:-''${HERDR_PANE_ID:-}}"
    [ -n "$pane" ] || exit 0
    status_file="$HERDR_PLUGIN_STATE_DIR/herdr-$(printf '%s' "$pane" | tr -c 'A-Za-z0-9_.-' '_').status"

    # A pane that closes, or gains or loses an agent, starts from a clean slate.
    case "''${HERDR_PLUGIN_EVENT:-}" in
      pane.closed | pane.agent_detected)
        rm -f "$status_file"
        exit 0
        ;;
    esac

    status=$(printf '%s' "$data" | ${jq} -r '.agent_status // empty')
    [ -n "$status" ] || exit 0
    previous=$(cat "$status_file" 2> /dev/null)
    printf '%s' "$status" > "$status_file"
    # Only a change into a status counts, not a repeat of it.
    [ "$status" != "$previous" ] || exit 0
    case "$status" in
      blocked) play ${lib.escapeShellArgs peonSounds.blocked} ;;
      working) play ${lib.escapeShellArgs peonSounds.working} ;;
      # Only a finished turn, not a new agent settling or a done pane being viewed.
      idle) [ "$previous" = working ] && play ${lib.escapeShellArgs peonSounds.end} ;;
    esac
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
    description = "Play SCV sounds for workspace open/close and agents starting, finishing or blocked"
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

    [[events]]
    on = "workspace.created"
    command = ["$out/peon-hook.sh"]

    [[events]]
    on = "workspace.closed"
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
