{
  description = "Dotfiles manager";

  inputs = {
    nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs = { nixpkgs.follows = "nixpkgs"; };
    };
  };

  outputs = { nixpkgs, home-manager, ... }: rec {
    lib = {
      createUserProfile = username: moduleList:
        let list = (builtins.map (m: (m username)) moduleList);
        in {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          imports = [ ((import ./options.nix) username) ] ++ list;
        };
    };

    options = import ./options.nix;
  };
}
