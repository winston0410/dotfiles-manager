username:
{ lib, pkgs, config, ... }:

with lib;

let
  programConfig = {
    package = mkOption {
      type = types.package;
      description = "Default package to use";
    };

    configPath = mkOption {
      type = types.path;
      description = "Path for configuration file";
    };
  };

  windowManagerConfig = {
    enable = false;
    # package = pkgs.leftwm;
    # configPath = ../dotfiles/leftwm/config.toml;
  };

  shellDefaultConfig = {
    enable = false;
    aliases = { };
    # package = pkgs.zsh;
    # configPath = ../dotfiles/.zshrc;
  };

  emulatorDefaultConfig = {
    enable = false;
    # package = pkgs.wezterm;
    # configPath = ../dotfiles/wezterm/wezterm.lua;
  };

  multiplexerDefaultConfig = {
    enable = false;
    # package = pkgs.tmux;
    # configPath = ../dotfiles/.tmux.conf;
  };

  cfg = config.dotfiles.terminal;

  aliasList =
    (mapAttrsToList (k: v: "alias ${k}=${escapeShellArg v}") cfg.shell.aliases);

  tomlFormat = pkgs.formats.toml { };
in {
  options.dotfiles.terminal = {
    windowManager = mkOption {
      type = types.submodule {
        options =
          (lib.recursiveUpdate { enable = mkEnableOption "window manager"; }
            programConfig);
      };
      default = shellDefaultConfig;
      description = "Configuration for window manager";
    };
    shell = mkOption {
      type = types.submodule {
        options = (lib.recursiveUpdate {
          enable = mkEnableOption "shell";
          aliases = mkOption {
            description = "Shell aliases that will be used by all shells";
            type = types.attrsOf types.str;
          };
          init = mkOption {
            default = "";
            type = types.lines;
            description = "Extra command for shell";
          };
        } programConfig);
      };
      default = shellDefaultConfig;
      description = "Configuration for shell";
    };
    emulator = mkOption {
      type = types.submodule {
        options = (lib.recursiveUpdate { enable = mkEnableOption "emulator"; }
          programConfig);
      };
      default = emulatorDefaultConfig;
      description = "Configuration for terminal emulator";
    };
    multiplexer = mkOption {
      type = types.submodule {
        options =
          (lib.recursiveUpdate { enable = mkEnableOption "multiplexer"; }
            programConfig);
      };
      default = multiplexerDefaultConfig;
      description = "Configuration for terminal multiplexer";
    };
  };

  config = (mkMerge [
    {
      assertions = [
        {
          assertion = cfg.shell.enable;
          message =
            config.lib.custom.addErrPrefix "You haven't defined any shell.";
        }
        {
          assertion = cfg.emulator.enable;
          message = config.lib.custom.addErrPrefix
            "You haven't defined any terminal emulator.";
        }
      ];
    }

    ((mkIf cfg.windowManager.enable) {
      services.xserver = {
        windowManager.leftwm = { enable = true; };
        displayManager = {
          defaultSession = "none+${cfg.windowManager.package.pname}";
        };
      };
      home-manager.users.${username} = let
        terminal = cfg.emulator.package;
        path = (config.lib.custom.getExecPath terminal);
      in {
        home.packages = [ cfg.shell.package ];

        xdg.configFile = mkMerge [
          (mkIf (cfg.windowManager.package.pname == "leftwm") {
            "leftwm/config.toml" = {
              source = (pkgs.writeText "leftwm-config"
                (config.lib.custom.hydratePlaceholder [ "#dotfile-manager" ]
                  [ "'${path}'" ] cfg.windowManager.configPath));
            };
          })
        ];
      };
    })

    ((mkIf cfg.shell.enable) {
      home-manager.users.${username} = let
      in {
        home.packages = [ cfg.shell.package ];

        home.file = let
          aliasList = (mapAttrsToList (k: v: "alias ${k}=${escapeShellArg v}")
            cfg.shell.aliases);
        in mkMerge [
          (mkIf (cfg.shell.package.pname == "zsh") {
            ".zshrc" = {
              text = (builtins.readFile cfg.shell.configPath) + ''
                ${(concatStringsSep "\n" aliasList)}
                ${cfg.shell.init}
              '';
            };
          })
        ];

        xdg.configFile = let
          initCommands = lib.strings.splitString "\n" cfg.shell.init;
          nushellExtra = {
            startup =
              (mapAttrsToList (k: v: "alias ${k} = ${v}") cfg.shell.aliases)
              ++ initCommands;
          };
        in mkMerge [
          (mkIf (cfg.shell.package.pname == "nushell") {
            "nu/config.toml" = {
              source = tomlFormat.generate "nushell-config"
                (lib.attrsets.recursiveUpdate
                  (lib.trivial.importTOML cfg.shell.configPath) nushellExtra);
            };
          })
        ];
      };
    })

    ((mkIf cfg.emulator.enable) {
      home-manager.users.${username} = let
        program = (if cfg.multiplexer.enable then
          cfg.multiplexer.package
        else
          cfg.shell.package);
        path = (config.lib.custom.getExecPath program);
      in {
        home.packages = [ cfg.emulator.package ];

        xdg.configFile = mkMerge [
          (mkIf (cfg.emulator.package.pname == "wezterm") {
            "wezterm/wezterm.lua" = {
              source = (pkgs.writeText "wezterm-config"
                (config.lib.custom.hydratePlaceholder
                  [ "--[[dotfile-manager--]]" ] [ "'${path}'" ]
                  cfg.emulator.configPath));
            };
          })

          (mkIf (cfg.emulator.package.pname == "alacritty") {
            "alacritty/alacritty.yml" = {
              source = (pkgs.writeText "alacritty-config"
                (config.lib.custom.hydratePlaceholder [ "#dotfile-manager" ]
                  [ "${path}" ] cfg.emulator.configPath));
            };
          })
        ];
      };
    })

    ((mkIf cfg.multiplexer.enable) {
      home-manager.users.${username} = let
        shell = cfg.shell.package;
        path = (config.lib.custom.getExecPath shell);
      in {
        home.packages = [ cfg.multiplexer.package ];

        home.file = mkMerge [
          (mkIf (cfg.multiplexer.package.pname == "tmux") {
            ".tmux.conf" = {
              text = (builtins.readFile cfg.multiplexer.configPath) + ''
                set -g default-shell ${path}  
              '';
            };
          })
        ];
      };
    })
  ]);
}
