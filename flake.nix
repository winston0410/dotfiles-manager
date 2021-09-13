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
      # username as last argument for easier partial application
      createProfile = moduleList: username:
        let list = (builtins.map (m: (m username)) moduleList);
        in {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          imports = [
            home-manager.nixosModules.home-manager
            ((import ./options.nix) username)
          ] ++ list;
        };
    };

    options = import ./options.nix;
  };
}
