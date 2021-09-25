{ lib, config, pkgs, ... }:

with lib;

let tomlFormat = pkgs.formats.toml { };
in {
  options = {
    dotfiles-manager.shellAliases = mkOption {
      default = { };
      description = ''
        A wrapper for shellAliases for bash, zsh and fish
      '';
      type = types.attrsOf types.str;
    };
  };

  config = {
    xdg.configFile = {
      "nu/config.toml" = let
        generated = tomlFormat.generate "nushell-config" {
          startup = (lib.attrsets.mapAttrsToList (k: v: "alias ${k} = ${v}")
            config.dotfiles-manager.shellAliases);
        };
      in { text = (builtins.readFile generated); };
    };

    programs.zsh.shellAliases = config.dotfiles-manager.shellAliases;
    programs.bash.shellAliases = config.dotfiles-manager.shellAliases;
    programs.fish.shellAliases = config.dotfiles-manager.shellAliases;
  };
}
