{ self, inputs, ... }: {
  modules = with inputs; [ ];
  exportedModules = [ ./orchard.nix ];
}
