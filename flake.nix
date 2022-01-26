{
  description = "orchard";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-21.11";
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
        inherit self inputs;
      };

      inherit (utils) forAllSystems vmBaseImage runCodeAnalysis;

      nixpkgsFor = let
        overlay-unstable = final: prev: {
          unstable = import inputs.nixpkgs-unstable {
            inherit (final) system;
            config.allowUnfree = true;
          };
        };

        customPackages = import ./pkgs;
      in forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = [ customPackages overlay-unstable ];
          config.allowUnfree = true;
        });

      mkDeployment = { system, configuration, initialDeploy ? false }: {
        nixpkgs = {
          pkgs = nixpkgsFor.${system};
          localSystem = { inherit system; };
        };

        # TODO: This is a weird hack to prevent sops-nix from failing the activation on the initial deploy, leading to
        #   NixOps locking itself out of the machine
        imports = let
          common = if initialDeploy then
            ({ config, lib, pkgs, ... }: {
              imports = [ ./modules ./programs ];

              orchard = {
                programs = { fish.enable = true; };
                services = { openssh.enable = true; };
              };
            })
          else
            ./machines/common.nix;
        in [ common configuration ];
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
            imports = [ sops-nix.nixosModules.sops ];
            nix.nixPath = [ "nixpkgs=${nixpkgs}" ];
            nixpkgs.pkgs = nixpkgsFor."x86_64-linux";
          }];
        };

        resources = import ./resources;

        builder = mkDeployment {
          configuration = ./machines/builder/configuration.nix;
          system = "x86_64-linux";
        };

        bastion = mkDeployment {
          configuration = ./machines/bastion/configuration.nix;
          system = "x86_64-linux";
        };

        htpc = mkDeployment {
          configuration = ./machines/htpc/configuration.nix;
          system = "x86_64-linux";
        };

        unifi = mkDeployment {
          configuration = ./machines/unifi/configuration.nix;
          system = "x86_64-linux";
        };

        monitor = mkDeployment {
          configuration = ./machines/monitor/configuration.nix;
          system = "x86_64-linux";
        };

        # vm = mkDeployment {
        #   configuration = ./machines/vm/configuration.nix;
        #   system = "x86_64-linux";
        # };
      };
    } // flake-utils.lib.eachSystem [ "x86_64-darwin" "x86_64-linux" ] (system:
      let pkgs = nixpkgs-unstable.legacyPackages.${system};
      in {
        checks = {
          nixfmt = runCodeAnalysis system "nixfmt" ''
            ${pkgs.nixfmt}/bin/nixfmt --check \
              $(find . -type f -name '*.nix')
          '';
        };

        devShell = pkgs.mkShell {
          nativeBuildInputs = with pkgs;
            [ age git nixfmt ssh-to-age sops ] ++ [
              nixops-plugged.defaultPackage.${system}
              sops-nix.defaultPackage.${system}
            ];

          # TODO: See if this can be done like the other environment variables
          shellHook = ''
            export AWS_ACCESS_KEY_ID=$(sops -d --extract '["aws_access_key_id"]' ./secrets.yaml)
            export AWS_SECRET_ACCESS_KEY=$(sops -d --extract '["aws_secret_access_key"]' ./secrets.yaml)
          '';

          NIXOPS_DEPLOYMENT = "orchard";
          NIXOPS_STATE = "./state.nixops";

          SOPS_AGE_KEY_DIR = "$HOME/.config/sops/age";
        };
      });
}
