{
  description = "Dotfiles manager";

  inputs = {
    nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs = { nixpkgs.follows = "nixpkgs"; };
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }: rec {
    lib = {
      # username as last argument for easier partial application
      mkProfile = { modules, username }:
        let list = (builtins.map (m: (m username)) modules);
        in {
          imports = [ ((import ./options.nix) username) ] ++ list;
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
        };

      mkSystem = { system, inputs, username, modules }:
        pkgs.lib.nixosSystem {
          inherit system;
          modules = [ (self.lib.mkProfile { inherit modules username; }) ];
          specialArgs = { inherit inputs; };
        };
    };

    options = import ./options.nix;
  };
}
