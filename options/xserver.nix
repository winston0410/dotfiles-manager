username:
{ lib, pkgs, config, ... }:

with lib;

let cfg = config.dotfiles.xserver;
in {
  options.dotfiles.xserver = {
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
    gtkCursorTheme = ''gtk-cursor-theme-name="${cfg.cursor.theme}"'';
    gtkCursorSize = "gtk-cursor-theme-size=${builtins.toString cfg.cursor.size}";
    gtkCommand = ''
      ${gtkCursorTheme}
      ${gtkCursorSize}
    '';
  in {
    home-manager.users.${username} = {
      home.packages = with pkgs; [ cfg.cursor.package ];

      home.sessionVariables = {
        XCURSOR_SIZE = "${builtins.toString cfg.cursor.size}";
        XCURSOR_THEME = "${cfg.cursor.theme}";
      };

      home.file = {
        ".icons/default" = {
          source = "${cfg.cursor.package}/share/icons/${cfg.cursor.theme}";
        };

        ".gtkrc-2.0" = { text = gtkCommand; };
      };

      xdg.configFile = { "gtk-3.0/setting.ini" = { text = gtkCommand; }; };
    };
  }));
}
