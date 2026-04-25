{ pkgs, peon-ping, ... }:
{
  enable = true;
  package = peon-ping.packages."${pkgs.system}".default;
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
      "session.end" = true;
      "task.complete" = true;
      "task.acknowledge" = false;
      "task.error" = true;
      "task.progress" = false;
      "input.required" = true;
      "resource.limit" = true;
      "user.spam" = true;
    };
  };
  installPacks = [ "sc_scv" ];
}
