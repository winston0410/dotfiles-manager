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
    lib = let
      mkExtendable = f: origArgs:
        let attrKeys = builtins.attrNames origArgs;
        in (
        # Use shallow merge as only adding the extend function there
        # Handle later
        (f origArgs) // {
          extend = newArgs:
            (mkExtendable f newArgs);
        });
    in {
      mkProfile = modules: username:
        let list = (builtins.map (m: (m username)) modules);
        in {
          imports = [ ((import ./options.nix) username) ] ++ list;
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
        };

      mkSystem = mkExtendable ({ system, inputs, modules }:
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ inputs.home-manager.nixosModules.home-manager ]
            ++ modules;
          specialArgs = { inherit inputs; };
        });
    };

    options = import ./options.nix;
  };
}
