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
      default = pkgs.${programName};
    };
  };
in {
  options.dotfiles.programs = {
    direnv = (programOptions "direnv");
    zoxide = (programOptions "zoxide");
  };

  config = (mkMerge [
    (mkIf cfg.direnv.enable (let
      configDict = {
        zsh = ''
          eval "$(${
            config.lib.custom.getBinPath cfg.direnv.package
          } hook zsh)"'';
      };
    in {
      home-manager.users.${username} = {
        home.packages = [ cfg.direnv.package ];
      };

      dotfiles.terminal.shell.init = configDict.${shellCfg.package.pname};
    }))

    (mkIf cfg.zoxide.enable (let
      configDict = {
        zsh =
          ''eval "$(${config.lib.custom.getBinPath cfg.zoxide.package} zsh)"'';
      };
    in {
      home-manager.users.${username} = {
        home.packages = [ cfg.zoxide.package ];
      };

      dotfiles.terminal.shell.init = configDict.${shellCfg.package.pname};
    }))
  ]);
}
