{ st, fetchurl }:

st.overrideAttrs (oldAttrs: rec {

  src = fetchurl {
    url = "http://dl.suckless.org/st/st-0.9.tar.gz";
    sha256 = "sha256-82NZeZc06ueFvss3QGPwvoM88i+ItPFpzSUbmTJOCOc=";
  };

  patches = [
    ./st-clipboard-0.8.2.diff
    ./st-dracula-0.8.5.diff
    ./st-font.diff
    ./st-latency.diff
  ];
})
