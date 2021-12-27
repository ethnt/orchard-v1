{ self, lib, inputs }:

let
  inherit (lib) genAttrs;

  systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" ];

  forAllSystems = f: genAttrs systems (sys: f sys);

  nixpkgsFor = let
    overlay-unstable = final: prev: {
      unstable = import inputs.nixpkgs-unstable {
        inherit (final) system;
        config.allowUnfree = true;
      };
    };
  in forAllSystems (system:
    import inputs.nixpkgs {
      inherit system;
      overlays = [ overlay-unstable ];
      config.allowUnfree = true;
    });

  vmBaseImage = { pkgs, ref ? "nixos-21.11"
    , rev ? "1158f3463912d54cc981d61213839ec6c02570d3" }:
    let
      vbox_src = builtins.fetchGit {
        url = "https://github.com/NixOS/nixpkgs";
        inherit rev ref;
      };
      machine = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          "${pkgs.nixops}/share/nix/nixops/virtualbox-image-nixops.nix"
          ./base.nix
        ];
      };
      ova = machine.config.system.build.virtualBoxOVA;
    in pkgs.runCommand
    "virtualbox-nixops-image-${machine.config.system.nixos.version}-v2" {
      nativeBuildInputs = [ ova ];
    } ''
      mkdir ova
      tar -xf ${ova}/*.ova -C ova
      mv ova/nixos*.vmdk $out
    '';

  runCodeAnalysis = system: name: command:
    nixpkgsFor.${system}.runCommand "orchard-${name}" { } ''
      cd ${self}
      ${command}
      mkdir $out
    '';

in { inherit forAllSystems nixpkgsFor vmBaseImage runCodeAnalysis; }
