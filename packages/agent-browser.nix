{ pkgs, unstable }:

pkgs.symlinkJoin {
  name = "agent-browser";
  paths = [ unstable.agent-browser ];
  nativeBuildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/agent-browser \
      --set-default AGENT_BROWSER_ARGS "--no-sandbox,--disable-setuid-sandbox,--disable-dev-shm-usage,--ignore-gpu-blocklist"
  '';
}
