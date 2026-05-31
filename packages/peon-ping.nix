{ pkgs, peon-ping, ... }:
{
  enable = true;
  package = peon-ping.packages."${pkgs.stdenv.hostPlatform.system}".default;
  claudeCodeIntegration = true;
  settings = {
    default_pack = "sc_scv";
    volume = 0.7;
    enabled = true;
    desktop_notifications = true;
    suppress_subagent_complete = true;
    #annoyed_threshold = 1;
    #annoyed_window_seconds = 10;
    categories = {
      "session.start" = false;
      "session.end" = false;
      "task.complete" = true;
      "task.acknowledge" = true;
      "task.error" = false;
      "task.progress" = false;
      "input.required" = false;
      "resource.limit" = true;
      "user.spam" = false;
    };
  };
  installPacks = [ "sc_scv" ];
}
