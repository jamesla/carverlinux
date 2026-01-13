{
  enable = true;
  lfs.enable = true;

  settings = {
    user = {
      email = "jamesgmccallum@gmail.com";
      name = "James McCallum";
    };

    core = {
      autocrlf = "false";
    };
  };

  extraConfig = {
    pull.rebase = true;
  };
}
