{ pkgs, workmux }:
let
  # Upstream's test suite has 3 sandbox-incompatible tests that hit real fs
  # paths (apple-container/lima mount canonicalization). They fail with
  # EACCES in the Nix build sandbox even though the binary is fine.
  workmuxPkg = workmux.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (_: {
    doCheck = false;
  });
in
{
  home.packages = [ workmuxPkg ];

  xdg.configFile."workmux/config.yaml".text = ''
    merge_strategy: rebase
    agent: claude
    nerdfont: true
    panes:
      - command: nvim
      - command: <agent>
        split: horizontal
        percentage: 50
        focus: true
      - split: vertical
  '';
}
