{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "multica";
  version = "0.4.20";

  src = fetchurl {
    url = "https://github.com/multica-ai/multica/releases/download/v${version}/multica-cli-${version}-linux-arm64.tar.gz";
    sha256 = "723486128035143e0b5fcc25f8f7a4621bd7a45d706916f0ccacbd3ea4ee8509";
  };

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 multica $out/bin/multica
    runHook postInstall
  '';
}
