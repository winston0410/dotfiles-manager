username:
{ lib, pkgs, config, ... }:

with lib;

let
  cfg = config.dotfiles.programs;
  shellCfg = config.dotfiles.terminal.shell;
  programOptions = programName: {
    enable = mkEnableOption programName;
    package = mkOption {
      type = types.package;
      description = "Default package for ${programName}";
      default = pkgs.direnv;
    };
  };
in {
  options.dotfiles.programs = {
    direnv = programOptions "direnv";
    zoxide = programOptions "zoxide";
  };

  config = (mkMerge [
    ((mkIf cfg.direnv.enable) mkMerge [
      {
        home-manager.users.${username} = {
          home.packages = [ cfg.direnv.package ];
        };
      }
      (mkIf (shellCfg.package.pname == "zsh") {
        dotfiles.terminal.shell.init = ''
          eval "$(${
            config.lib.custom.getBinPath cfg.direnv.package
          } hook zsh)"'';
      })

      # (mkIf (shellCfg.package.pname == "nushell") {
      # dotfiles.terminal.shell.init = ''eval "$(direnv hook zsh)"'';
      # })
    ])

    ((mkIf cfg.zoxide.enable) mkMerge [
      {
        home-manager.users.${username} = {
          home.packages = [ cfg.zoxide.package ];
        };
      }
      (mkIf (shellCfg.package.pname == "zsh") {
        dotfiles.terminal.shell.init =
          ''eval "$(${config.lib.custom.getBinPath cfg.zoxide.package} zsh)"'';
      })

      # (mkIf (shellCfg.package.pname == "nushell") {
      # dotfiles.terminal.shell.init = ''eval "$(direnv hook zsh)"'';
      # })
    ])
  ]);
}
