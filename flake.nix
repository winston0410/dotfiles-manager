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
      # Handle merging logic later
      callback = name: vals: vals;

      mkExtendable = f: origArgs:
        let attrKeys = builtins.attrNames origArgs;
        in ((f origArgs) // {
          extend = newArgs:
            (mkExtendable f
              (nixpkgs.lib.attrsets.zipAttrsWithNames attrKeys callback [
                origArgs
                newArgs
              ]));
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
