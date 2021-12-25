{
  description = "orchard";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-21.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    nixops.url = "github:input-output-hk/nixops-flake";

    flake-utils.url = "github:numtide/flake-utils";

    flakebox.url = "github:esselius/nix-flakebox";
    flakebox.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self, nixpkgs, nixpkgs-unstable, nixops, flake-utils, ... }@inputs:
    let
      utils = import ./lib/utils.nix {
        inherit (nixpkgs) lib;
        inherit inputs;
      };

      inherit (utils) forAllSystems vmBaseImage;

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

        vm = { config, pkgs, ... }: {
          deployment = {
            targetEnv = "virtualbox";
            virtualbox = {
              memorySize = 2048;
              headless = true;
            };
          };
        };
      };
    } // flake-utils.lib.eachSystem [ "x86_64-darwin" ] (system:
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
