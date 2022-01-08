final: prev: {
  blocky = prev.callPackage ./blocky.nix {
    buildGoModule = prev.buildGoModule.override { go = prev.go_1_17; };
  };
}
