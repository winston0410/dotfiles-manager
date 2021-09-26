nixpkgs:
let
  # override all datatypes except lists, which will be extended(inheritance) instead
  # Deprecated at the moment
  # extendAttrs = oldArgs: newArgs:
  # let
  # zipped = nixpkgs.lib.attrsets.zipAttrs [ oldArgs newArgs ];

  # foldFn = value:
  # (nixpkgs.lib.lists.foldl (acc: cur:
  # if builtins.isList cur then
  # acc ++ cur
  # else
  # (if (builtins.isAttrs cur) then (extendAttrs acc cur) else cur))
  # (if (builtins.isList (builtins.elemAt value 0)) then [ ] else { })
  # value);
  # mapFn = (_: value: (foldFn value));

  # in (nixpkgs.lib.attrsets.mapAttrs (mapFn) zipped);

  mkExtendable = f: origArgs:
    let
      # Only accept function as the result.
      result = (f origArgs);

      extendAttrs = oldArgs: newArgs:
        nixpkgs.lib.attrsets.recursiveUpdate oldArgs newArgs;

      # setFunctionArgs returns a set???
    in (nixpkgs.lib.setFunctionArgs result (nixpkgs.lib.functionArgs result)
      // {
        # TODO: Fix error where recursion behavior doesn't work here
        override = newArgs: (f (extendAttrs origArgs newArgs));
        # override = newArgs: (mkExtendable (f (extendAttrs origArgs newArgs)));
      });

  toList = nixpkgs.lib.attrsets.mapAttrsToList (_: value: value);

  mkSystem = mkExtendable ({ system, inputs, modules ? { } }:
    let
      hasHm = (builtins.hasAttr "home-manager" inputs)
        || (builtins.hasAttr "hm" inputs);
      injected = (builtins.map (m:
        let
          imported = if builtins.isPath m then (import m) inputs.nixpkgs else m;
          checked = imported;
        in (checked)) (toList modules));

    in (inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      # modules = (injected) ++ (inputs.nixpkgs.lib.optional hasHm
      modules = (toList modules) ++ (inputs.nixpkgs.lib.optional hasHm
        inputs.home-manager.nixosModules.home-manager);
      specialArgs = { inherit inputs system; };
    }));
in {
  mkProfile = mkExtendable
    ({ modules ? { }, hmModules ? { }, namedModules ? { }, userProfile ? { } }:
      # return an NixOS module to prevent leaking extend/override into configuration
      ({ ... }:
        let applyName = builtins.map (m: (m userProfile.name));
        in {
          imports = (toList modules)
            ++ (nixpkgs.lib.trivial.pipe namedModules [ toList applyName ]);
          # create user profile here
          users.users.${userProfile.name} = userProfile;

          # Handle home-manager modules
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.${userProfile.name} = {
            imports = (toList hmModules);
          };
        }));

  inherit mkSystem;

  mkSimpleSystem = mkExtendable
    ({ system, inputs, modules ? { }, hostname ? "nixos" }: {
      nixosConfigurations = {
        ${hostname} = (mkSystem { inherit system inputs modules; });
      };
    });
}
