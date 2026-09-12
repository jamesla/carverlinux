{ pkgs, ... }:
{
  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    permission = {
      read = "allow";
      edit = "allow";
      glob = "allow";
      grep = "allow";
      list = "allow";
      bash = "allow";
      task = "allow";
      external_directory = "allow";
      lsp = "allow";
      skill = "allow";
      todowrite = "allow";
      question = "allow";
      webfetch = "allow";
      websearch = "allow";
      doom_loop = "allow";
    };
  };
}
