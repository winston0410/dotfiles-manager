username:
{ lib, config, ... }:

with lib;

{
  imports = (lib.lists.forEach [
    ./options/terminal.nix
    ./options/programs.nix
    ./options/xserver.nix
  ] (module: (import module) username));

  config.lib.custom = let
    # Make this function private
    getBinPath = package:
      if (builtins.hasAttr "shellPath" package) then
        package.shellPath
      else
        "/bin/${package.pname}";
    addErrPrefix = str: "Dotfile Manager: " + str;
  in {
    addErrPrefix = addErrPrefix;
    getExecPath = package: "${package}${(getBinPath package)}";
    hydratePlaceholder = from: to: path:
      let
        str = (builtins.readFile path);
        replaced = (builtins.replaceStrings from to str);
      in (if (replaced != str) then
        replaced
      else
        (abort (addErrPrefix
          "Placeholder replacement failed for '${path}'. Have you included the placeholder in your config?")));
  };
}
