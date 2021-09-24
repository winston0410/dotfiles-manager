{ lib, config, pkgs, ... }:

with lib;

let tomlFormat = pkgs.formats.toml { };
in {
  imports = [ ./options/shellAliases.nix ];

  config = {
    home.file = {
      ".zshrc" = { text = config.programs.zsh.initExtra; };
      ".bashrc" = { text = config.programs.bash.initExtra; };
    };

    xdg.configFile = {
      "fish/config.fish" = { text = config.programs.fish.shellInit; };
    };
  };
}
