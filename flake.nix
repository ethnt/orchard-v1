{
  description = "orchard";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-21.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    nixops.url = "github:input-output-hk/nixops-flake";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self, nixpkgs, nixpkgs-unstable, nixops, flake-utils, ... }@inputs:
    let
      utils = import ./lib/utils.nix {
        inherit (nixpkgs) lib;
        inherit inputs;
      };

      inherit (utils) forAllSystems;

      nixpkgsFor = let
        overlay-unstable = final: prev: {
          unstable = import inputs.nixpkgs-unstable {
            inherit (final) system;
            config.allowUnfree = true;
          };
        };
      in forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = [ overlay-unstable ];
          config.allowUnfree = true;
        });

      mkDeployment = { system, configuration }: {
        nixpkgs = {
          pkgs = nixpkgsFor.${system};
          localSystem = { inherit system; };
        };

        imports = [ configuration ];
      };
    in {
      nixopsConfigurations.default = {
        inherit nixpkgs;

        network = {
          description = "orchard";
          enableRollback = true;
        };

        defaults = import ./machines/common.nix;

        resources = import ./resources;

        funnel = mkDeployment {
          configuration = ./machines/funnel/configuration.nix;
          system = "x86_64-linux";
        };

        builder = mkDeployment {
          configuration = ./machines/builder/configuration.nix;
          system = "x86_64-linux";
        };
      };
    } // flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs-unstable.legacyPackages.${system};
      in {
        devShell = pkgs.mkShell {
          nativeBuildInputs = with pkgs;
            [ git git-crypt nixfmt ] ++ [ nixops.defaultPackage."${system}" ];

          shellHook = ''
            export NIXOPS_DEPLOYMENT=orchard
          '';

          NIXOPS_STATE = "./state.nixops";
        };
      });
}
