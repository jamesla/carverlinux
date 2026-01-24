{ pkgs, ... }:

let
  caBundle = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
in pkgs.writeShellScriptBin "claude" ''
  export SSL_CERT_FILE="${caBundle}"
  export NODE_EXTRA_CA_CERTS="${caBundle}"
  export CURL_CA_BUNDLE="${caBundle}"
  export NODE_OPTIONS="--tls-min-v1.2 --tls-max-v1.2"
  export CURL_SSLVERSION="tlsv1.2"
  exec ${pkgs.claude-code}/bin/claude "$@"
''
