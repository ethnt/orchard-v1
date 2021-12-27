{
  description = "orchard";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-21.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    nixops-plugged.url = "github:ethnt/nixops-plugged";

    sops-nix.url = "github:Mic92/sops-nix";

    flake-utils.url = "github:numtide/flake-utils";

    flakebox.url = "github:esselius/nix-flakebox";
    flakebox.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixops-plugged, sops-nix
    , flake-utils, ... }@inputs:
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

        defaults = { ... }: {
          imports = [{
            imports = [ ./machines/common.nix ];
            nix.nixPath = [ "nixpkgs=${nixpkgs}" ];
            nixpkgs.pkgs = nixpkgsFor."x86_64-linux";
          }];
        };

        resources = import ./resources;

        builder = mkDeployment {
          configuration = ./machines/builder/configuration.nix;
          system = "x86_64-linux";
        };

        monitor = mkDeployment {
          configuration = ./machines/monitor/configuration.nix;
          system = "x86_64-linux";
        };

        vm = mkDeployment {
          configuration = ./machines/vm/configuration.nix;
          system = "x86_64-linux";
        };
      };
    } // flake-utils.lib.eachSystem [ "x86_64-darwin" ] (system:
      let pkgs = nixpkgs-unstable.legacyPackages.${system};
      in {
        devShell = pkgs.mkShell {
          nativeBuildInputs = with pkgs;
            [
              age
              git
              git-crypt
              nebula
              nixfmt
              ssh-to-pgp
              (pkgs.callPackage sops-nix { }).sops-import-keys-hook
            ] ++ [ nixops-plugged.defaultPackage.${system} ];

          shellHook = ''
            export NIXOPS_DEPLOYMENT=orchard
          '';

          NIXOPS_STATE = "./state.nixops";
        };
      });
}
