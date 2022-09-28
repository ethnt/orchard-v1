{
  description = "orchard";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    flake-utils.url = "github:numtide/flake-utils";

    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixpkgs-master, sops-nix
    , flake-utils, devshell, ... }@inputs:
    let
      pkgsFor = system:
        let unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
        in import nixpkgs {
          localSystem = { inherit system; };
          overlays = [ (self: super: { prowlarr = unstable.prowlarr; }) ];
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
    } // flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs-unstable.legacyPackages.${system};
      in {
        apps = import ./apps { inherit self pkgs; };
        lib = import ./lib { lib = flake-utils.lib // nixpkgs.lib; };
        devShell = import ./shell { inherit self pkgs; };
      });
}
