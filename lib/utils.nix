{ lib, inputs }:

let
  inherit (lib) genAttrs;

  systems = [ "x86_64-linux" "aarch64-linux" ];

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

in { inherit forAllSystems nixpkgsFor; }
