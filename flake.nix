{
  description = "orchard";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-21.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    nixops.url = "github:input-output-hk/nixops-flake";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, nixops, flake-utils }:
    let
      inherit (nixpkgs) lib;

      # List of all platforms we're supporting
      platforms = [ "x86_64-linux" ];

      # Generates a nixpkgs configuration for each platform
      nixpkgsFor = let
        overlay-unstable = final: prev: {
          unstable = import inputs.nixpkgs-unstable {
            system = final.system;
            config.allowUnfree = true;
          };
        };
      in flake-utils.forAllPlatforms (platform:
        import nixpkgs {
          system = platform;
          overlays = [ overlay-unstable ];
          config.allowUnfree = true;
        });

      mkDeployment = { host, platform, machineName, machineConfiguration ?
          ./machines + "/${machineName}/configuration.nix", secrets ? { } }: {
            deployment = {
              targetHost = host;
              keys = secrets;
            };

            nixpkgs = {
              pkgs = nixpkgsFor.${platform};
              localSystem.system = platform;
            };

            imports = [ machineConfiguration ];
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

        funnel = import ./machines/funnel;
      };
    } // flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs-unstable.legacyPackages.${system};
      in {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs;
            [ nixfmt ] ++ [ nixops.defaultPackage."${system}" ];

          shellHook = ''
            export AWS_ACCESS_KEY_ID=foo
            export AWS_SECRET_ACCESS_KEY=bar
            export NIXOPS_DEPLOYMENT=orchard
          '';
        };
      });
}
