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
      # mkExtendable = f: origArgs:
      # ((f origArgs) // {
      # extend = newArgs:
      # (mkExtendable f
      # (nixpkgs.lib.attrsets.recursiveUpdate origArgs newArgs));
      # });

      mkExtendable = f: origArgs: newArgs:
        f (nixpkgs.lib.attrsets.recursiveUpdate origArgs
          (builtins.removeAttrs newArgs [ "modules" ]));

    in {
      mkProfile = mkExtendable ({ modules }:
        username:
        let list = (builtins.map (m: (m username)) modules);
        in {
          imports = [ ((import ./options.nix) username) ] ++ list;
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
        });

      # mkSystem = mkExtendable
      # ({ system, inputs, modules ? [ ], extraModules ? [ ] }:
      # inputs.nixpkgs.lib.nixosSystem {
      # inherit system;
      # modules = modules ++ extraModules;
      # specialArgs = { inherit inputs; };
      # });

      mkSystem = mkExtendable
        ({ system, inputs, modules ? [ ], extraModules ? [ ] }:
          inputs.nixpkgs.lib.nixosSystem {
            inherit system;
            modules = modules ++ extraModules;
            specialArgs = { inherit inputs system; };
          });
    };

    options = import ./options.nix;
  };
}
