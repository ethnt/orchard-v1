{
  description = "orchard";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-21.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    terranix = {
      url = "github:terranix/terranix";
      inputs = { nixpkgs.follows = "nixpkgs"; };
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, terranix, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs-unstable.legacyPackages.${system};
        terraform = "${pkgs.terraform_0_15}/bin/terraform";
        terranixConfiguration = terranix.lib.buildTerranix {
          inherit pkgs;
          terranix_config.imports = [ ./infra/config.nix ];
        };
      in {
        apps = {
          infra = rec {
            type = "app";

            compile = {
              type = "app";
              program = toString (pkgs.writers.writeBash "compile" ''
                if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
                cp ${terranixConfiguration}/config.tf.json config.tf.json
              '');
            };

            apply = {
              type = "app";
              program = toString (pkgs.writers.writeBash "apply" ''
                if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
                cp ${terranixConfiguration}/config.tf.json config.tf.json \
                  && ${terraform} init \
                  && ${terraform} apply
              '');
            };

            destroy = {
              type = "app";
              program = toString (pkgs.writers.writeBash "destroy" ''
                if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
                cp ${terranixConfiguration}/config.tf.json config.tf.json \
                  && ${terraform} init \
                  && ${terraform} destroy
              '');
            };
          };

          deploy = {
            type = "app";

            program = self.apps.${system}.infra.apply;
          };
        };

        checks = let
          runCodeAnalysis = name: command:
            pkgs.runCommand "orchard-${name}" { } ''
              cd ${self}
              ${command}
              mkdir $out
            '';
        in {
          lint = runCodeAnalysis "nixfmt" ''
            ${pkgs.nixfmt}/bin/nixfmt --check \
              $(find . -type f -name '*.nix')
          '';
        };

        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            terraform_0_15
            terranix.defaultPackage.${system}
            nixfmt
          ];
        };
      });
}
