{
  description = "orchard";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";

    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixpkgs-master, sops-nix
    , flake-utils, ... }@inputs:
    let
      pkgsFor = let
        overlay-unstable = final: prev: {
          unstable = inputs.nixpkgs-unstable.legacyPackages.${final.system};
        };
      in system:
      import nixpkgs {
        inherit system;
        overlays = [ overlay-unstable ];
        config.allowUnfree = true;
      };

      mkDeployment = { system, configuration, initialDeploy ? false }: {
        nixpkgs = {
          pkgs = pkgsFor system;
          localSystem = { inherit system; };
        };

        # TODO: This is a weird hack to prevent sops-nix from failing the activation on the initial deploy, leading to
        #   NixOps locking itself out of the machine
        imports = let
          common = if initialDeploy then
            ({ config, lib, pkgs, ... }: {
              imports = [ ./modules ];

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
          storage.legacy.databasefile = "./state.nixops";
        };

        defaults = { ... }: {
          imports = [{
            imports = [ sops-nix.nixosModules.sops ];
            nix.nixPath = [ "nixpkgs=${nixpkgs}" ];
            nixpkgs.pkgs = pkgsFor "x86_64-linux";
          }];
        };

        resources = import ./resources;

        # gateway = mkDeployment {
        #   configuration = ./machines/gateway/configuration.nix;
        #   system = "x86_64-linux";
        # };

        htpc = mkDeployment {
          configuration = ./machines/htpc/configuration.nix;
          system = "x86_64-linux";
        };

        monitor = mkDeployment {
          configuration = ./machines/monitor/configuration.nix;
          system = "x86_64-linux";
        };

        matrix = mkDeployment {
          configuration = ./machines/matrix/configuration.nix;
          system = "x86_64-linux";
        };

        errata = mkDeployment {
          configuration = ./machines/errata/configuration.nix;
          system = "x86_64-linux";
        };

        portal = mkDeployment {
          configuration = ./machines/portal/configuration.nix;
          system = "x86_64-linux";
        };
      };
    } // flake-utils.lib.eachSystem [ "x86_64-darwin" "x86_64-linux" ] (system:
      let pkgs = nixpkgs-unstable.legacyPackages.${system};
      in {
        checks = let
          runCodeAnalysis = name: command:
            pkgs.runCommand "orchard-${name}" { } ''
              cd ${self}
              ${command}
              mkdir $out
            '';
        in {
          nixfmt = runCodeAnalysis "nixfmt" ''
            ${pkgs.nixfmt}/bin/nixfmt --check \
              $(find . -type f -name '*.nix')
          '';
        };

        devShell = pkgs.mkShell {
          nativeBuildInputs = with pkgs;
            [ age git git-crypt nixfmt ssh-to-age sops nixopsUnstable ]
            ++ [ sops-nix.defaultPackage.${system} ];

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
