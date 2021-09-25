{ lib, config, pkgs, ... }:

with lib;

{
  imports = [ ./options/shellAliases.nix ];
}
