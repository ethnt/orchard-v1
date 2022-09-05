{
  description = "orchard";

  nixConfig.extra-experimental-features = "nix-command flakes";
  nixConfig.extra-substituters =
    "https://orchard.cachix.org https://nrdxp.cachix.org https://nix-community.cachix.org";
  nixConfig.extra-trusted-public-keys =
    "orchard.cachix.org-1:QfoahY05xLNfFqWoWCELCMz2I8I92n5W8wNRJo+YT2U= nrdxp.cachix.org-1:Fc5PSqY2Jm1TrWfm88l6cvGWwz3s93c6IOifQWnhNW4= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    digga.url = "github:divnix/digga";
    digga.inputs.nixpkgs.follows = "nixpkgs";
    digga.inputs.nixlib.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, digga, flake-utils, ... }@inputs:
    digga.lib.mkFlake {
      inherit self inputs;

      channelsConfig = { allowUnfree = true; };

      channels = { nixpkgs = { overlays = [ ]; }; };

      lib = import ./lib { lib = digga.lib // nixpkgs.lib; };

      sharedOverlays = [
        (final: prev: {
          __dontExport = true;
          lib = prev.lib.extend (lfinal: lprev: { our = self.lib; });
        })
      ];

      nixos = {
        hostDefaults = {
          system = "x86_64-linux";
          channelName = "nixpkgs";
          modules = [{ lib.our = self.lib; }];
        };
      };

      devshell = ./shell;

      outputsBuilder = channels:
        let pkgs = channels.nixpkgs;
        in { apps = import ./apps { inherit self pkgs; }; };
    };
}
