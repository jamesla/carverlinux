{
  enable = true;
  enableDefaultConfig = false;
  settings = {
    "anton" = {
      HostName = "192.168.1.252";
      User = "james";
    };
    "skynet" = {
      HostName = "192.168.1.253";
      User = "james";
    };
    "*" = {
      ForwardAgent = true;
      AddKeysToAgent = false;
      ServerAliveInterval = 0;
      ServerAliveCountMax = 3;
      UserKnownHostsFile = "~/.ssh/known_hosts";
    };
  };
}
