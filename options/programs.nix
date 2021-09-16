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
            config.lib.custom.getExecPath cfg.direnv.package
          } hook zsh)"'';
      };
    in {
      home-manager.users.${username} = {
        home.packages = [ cfg.direnv.package ];
      };

      dotfiles.terminal.shell.init = configDict.${shellCfg.package.pname};

      xdg.configFile = mkMerge [
        (mkIf (cfg.direnv.package.pname == "nix-direnv") {
          "direnv/direnvrc" = {
            text = "${cfg.direnv.package}/share/nix-direnv/direnvrc";
          };
        })
      ];
    }))

    (mkIf cfg.zoxide.enable (let
      configDict = {
        zsh = ''
          eval "$(${
            config.lib.custom.getExecPath cfg.zoxide.package
          } init zsh)"'';
      };
    in {
      home-manager.users.${username} = {
        home.packages = [ cfg.zoxide.package ];
      };

      dotfiles.terminal.shell.init = configDict.${shellCfg.package.pname};

      dotfiles.terminal.shell.aliases = { z = "zoxide"; };
    }))
  ]);
}
