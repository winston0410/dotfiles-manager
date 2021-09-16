username:
{ lib, pkgs, config, ... }:

with lib;

let cfg = config.dotfiles.xserver;
in {
  options.dotfiles.xserver = {
    bar = {
      enable = mkEnableOption "Bar configuration";
      package = mkOption {
        type = types.package;
        description = "Default package for bar";
      };
    };
    cursor = {
      enable = mkEnableOption "Cursor configuration for gtk and x";
      size = mkOption {
        type = types.ints.positive;
        description = "Cursor size";
        default = 80;
      };
      package = mkOption {
        type = types.package;
        description = "Default package for cursor";
        default = pkgs.bibata-cursors;
      };
      theme = mkOption {
        type = types.nonEmptyStr;
        description = "Default theme for cursor";
        default = "Bibata_Ice";
      };
    };
  };

  config = (mkIf cfg.cursor.enable (let
    sizeStr = builtins.toString cfg.cursor.size;
    gtkCursorTheme = ''gtk-cursor-theme-name="${cfg.cursor.theme}"'';
    gtkCursorSize = "gtk-cursor-theme-size=${sizeStr}";
    gtkCommand = ''
      ${gtkCursorTheme}
      ${gtkCursorSize}
    '';
  in {
    # TODO: Handle option for disabling theme
    home-manager.users.${username} = {
      home.packages = with pkgs; [ cfg.cursor.package ];

      home.file = {
        ".Xresources" = {
          text = ''
            Xcursor.size: ${sizeStr}
            Xcursor.theme: ${cfg.cursor.theme}
          '';
        };
        ".icons/default" = {
          source = "${cfg.cursor.package}/share/icons/${cfg.cursor.theme}";
        };

        ".gtkrc-2.0" = { text = gtkCommand; };
      };

      xdg.configFile = { "gtk-3.0/setting.ini" = { text = gtkCommand; }; };

      xsession.initExtra = "${
          config.lib.custom.getExecPath pkgs.xorg.xrdb
        } -merge $HOME/.Xresources";
    };

    dotfiles.terminal.shell.variables = {
      XCURSOR_SIZE = "${sizeStr}";
      XCURSOR_THEME = "${cfg.cursor.theme}";
    };
  }));
}
