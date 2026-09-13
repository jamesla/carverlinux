{ pkgs, ... }:

pkgs.stdenv.mkDerivation rec {
  pname = "agent-browser";
  version = "0.37.1";

  src = pkgs.fetchurl {
    url = "https://github.com/vercel-labs/agent-browser/releases/download/v${version}/agent-browser-linux-arm64";
    hash = "sha256-1U0+EmLcGqCQbgZ3rcbQy7QNEnRjH0z3cTa/I6C8IOk=";
  };

  dontUnpack = true;

  nativeBuildInputs = [ pkgs.autoPatchelfHook pkgs.makeWrapper ];
  buildInputs = [ pkgs.stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/agent-browser
    runHook postInstall
  '';

  # Force software GL (SwiftShader) so the browser it launches renders inside
  # the VM's limited GPU. Uses agent-browser's own AGENT_BROWSER_ARGS env var;
  # --set-default keeps it overridable at runtime.
  postFixup = ''
    wrapProgram $out/bin/agent-browser \
      --set-default AGENT_BROWSER_ARGS "--use-gl=swiftshader,--no-sandbox,--disable-setuid-sandbox,--disable-dev-shm-usage,--ignore-gpu-blocklist"
  '';

  meta = with pkgs.lib; {
    description = "Standalone browser automation daemon for AI agents";
    homepage = "https://github.com/vercel-labs/agent-browser";
    license = licenses.asl20;
    platforms = [ "aarch64-linux" ];
    mainProgram = "agent-browser";
  };
}
