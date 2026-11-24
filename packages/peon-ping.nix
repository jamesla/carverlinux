{ pkgs, peon-ping, ... }:
{
  enable = true;
  package = peon-ping.packages."${pkgs.stdenv.hostPlatform.system}".default;
  # Sounds are driven by herdr agent status (see peonPlugin in herdr.nix), not
  # by Claude Code hooks.
  claudeCodeIntegration = false;
  settings = {
    default_pack = "sc_scv";
    volume = 0.7;
    enabled = true;
    desktop_notifications = true;
    suppress_subagent_complete = true;
    #annoyed_threshold = 1;
    #annoyed_window_seconds = 10;
    categories = {
      "session.start" = true;
      "session.end" = true;
      "task.complete" = false;
      "task.acknowledge" = false;
      "task.error" = true;
      "task.progress" = false;
      "input.required" = false;
      "resource.limit" = true;
      "user.spam" = false;
    };
  };
  installPacks = [ "sc_scv" ];
}
