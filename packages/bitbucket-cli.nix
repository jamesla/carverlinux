{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "bitbucket-cli";
  version = "0.17.0";

  src = fetchFromGitHub {
    owner = "avivsinai";
    repo = "bitbucket-cli";
    rev = "v${version}";
    hash = "sha256-Hn8FS9+SVmabBOwqT2XpqoxKououNnW75THcGx4nYtA=";
  };

  vendorHash = "sha256-6H4+CHSXJYRDlx12Iz9R129VIiA0NB/5g7JMgGwYwkE=";

  subPackages = [ "cmd/bkt" ];

  meta = {
    description = "Bitbucket CLI tool";
    homepage = "https://github.com/avivsinai/bitbucket-cli";
    license = lib.licenses.mit;
    mainProgram = "bkt";
  };
}
