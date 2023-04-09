{ st, fetchurl }:

st.overrideAttrs (oldAttrs: rec {

  src = fetchurl {
    url = "http://dl.suckless.org/st/st-0.8.2.tar.gz";
    sha256 = "aeb74e10aa11ed364e1bcc635a81a523119093e63befd2f231f8b0705b15bf35";
  };

  patches = [
    ./st-alpha-0.8.2.diff
    ./st-clipboard-0.8.2.diff
    ./st-no_bold_colors-0.8.1.diff
    ./st-solarised-dark-after-alpha-0.8.2.diff
  ];
})
