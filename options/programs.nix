username:
{ lib, pkgs, config, ... }:

with lib;

let
  cfg = config.dotfiles.programs;
  shellCfg = config.dotfiles.terminal.shell;
in {
  options.dotfiles.programs = {
    direnv = {
      enable = mkEnableOption "direnv";
      package = mkOption {
        type = types.package;
        description = "Default direnv package";
        default = pkgs.direnv;
      };
    };
  };

  config = (mkMerge [
    ((mkIf cfg.direnv.enable) mkMerge [
      {
        home-manager.users.${username} = {
          home.packages = [ cfg.direnv.package ];
        };
      }
      (mkIf (shellCfg.package.pname == "zsh") {
        dotfiles.terminal.shell.init = ''eval "$(direnv hook zsh)"'';
      })

      (mkIf (shellCfg.package.pname == "nushell") {
        dotfiles.terminal.shell.init = ''eval "$(direnv hook zsh)"'';
      })
    ])
  ]);
}
