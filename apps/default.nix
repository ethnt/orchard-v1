{ self, pkgs, }: {
  repl = self.inputs.flake-utils-plus.lib.mkApp {
    drv = pkgs.writeShellScriptBin "repl" ''
      nix repl --argstr flakePath "${self}" ${./repl}
    '';
  };
}
