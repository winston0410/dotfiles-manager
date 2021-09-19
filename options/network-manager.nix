username:
{ lib, pkgs, config, ... }:

with lib;

let
  cfg = config.dotfiles.network-manager;

  networkProfile = types.submodule {
    options = {
      ssid = mkOption {
        description = "Name of the network";
        type = types.str;
      };
      # TODO: hash it
      psk = mkOption {
        description = "Password of the network";
        type = types.str;
      };
    };
  };
in {
  options.dotfiles.network-manager = {
    profiles = mkOption {
      type = types.attrsOf networkProfile;
      description = "Profiles for network connection";
      default = { };
    };
  };

  config = mkIf (config.networking.networkmanager.enable) {
    environment.etc = (mkIf (cfg.profiles != { }) {

    });
  };
}
