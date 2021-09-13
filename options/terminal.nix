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
        options = (lib.recursiveUpdate { enable = mkEnableOption "shell"; }
          programConfig);
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
    # (mkIf (not cfg.windowManager.enable) abort
    # (config.lib.custom.addErrPrefix "You haven't defined any window manager."))

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

    # (mkIf (not cfg.shell.enable) abort
    # (config.lib.custom.addErrPrefix "You haven't defined any shell."))

    ((mkIf cfg.shell.enable) {
      # Hardcode right now. Not sure how to solve it
      home-manager.users.${username} = let
      in {
        home.packages = [ cfg.shell.package ];

        home.file = mkMerge [
          (mkIf (cfg.shell.package.pname == "zsh") {
            ".zshrc" = { source = cfg.shell.configPath; };
          })
        ];

        xdg.configFile = mkMerge [
          (mkIf (cfg.shell.package.pname == "nushell") {
            "nu/config.toml" = { source = cfg.shell.configPath; };
          })
        ];
      };
    })

    # (mkIf (not cfg.emulator.enable) abort
    # (config.lib.custom.addErrPrefix "You haven't defined any terminal."))

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
