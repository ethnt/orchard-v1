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
        # terranixConfiguration = terranix.lib.buildTerranix {
        #   inherit pkgs;
        #   terranix_config.imports = [ ./infra/config.nix ];
        # };
        terraformConfiguration = terranix.lib.terranixConfiguration {
          inherit system;
          modules = [ ./infra/config.nix ];
        };
      in rec {
        apps = rec {
          infra = rec {
            type = "app";

            compile = {
              type = "app";
              program = toString (pkgs.writers.writeBash "compile" ''
                if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
                cp ${terraformConfiguration}/config.tf.json config.tf.json
              '');
            };

            apply = {
              type = "app";
              program = toString (pkgs.writers.writeBash "apply" ''
                ${compile.program} \
                  ${terraform} init \
                  ${terraform} apply
              '');
            };

            destroy = {
              type = "app";
              program = toString (pkgs.writers.writeBash "destroy" ''
                ${compile.program} \
                  ${terraform} init \
                  ${terraform} destroy
              '');
            };
          };

          deploy = {
            type = "app";

            program = toString (pkgs.writers.writeBash "deploy" ''
              ${infra.apply.program}
            '');
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

          validate = runCodeAnalysis "terraform-validate" ''
            ${apps.infra.compile.program} \
              && ${terraform} init \
              && ${terraform} validate
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
