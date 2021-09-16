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
    direnv = (lib.attrsets.recursiveUpdate (programOptions "direnv") {
      nix-direnv = { enable = mkEnableOption "nix-direnv"; };
    });
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
        home.packages = [ cfg.direnv.package ]
          ++ (lib.lists.optional cfg.direnv.nix-direnv.enable
            (pkgs.nix-direnv.override { enableFlakes = true; }));

        xdg.configFile = mkMerge [
          (mkIf (cfg.direnv.nix-direnv.enable) {
            "direnv/direnvrc" = {
              text = "source ${pkgs.nix-direnv}/share/nix-direnv/direnvrc";
            };
          })
        ];
      };

      nix = (mkIf (cfg.direnv.nix-direnv.enable) {
        extraOptions = ''
          keep-outputs = true
          keep-derivations = true
        '';
      });

      dotfiles.terminal.shell.init = configDict.${shellCfg.package.pname};
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
