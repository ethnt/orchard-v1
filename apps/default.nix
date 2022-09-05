{ self, pkgs, }: {
  repl = self.inputs.flake-utils.lib.mkApp {
    drv = pkgs.writeShellScriptBin "repl" ''
      nix repl --argstr flakePath "${self}" ${./repl}
    '';
  };
}
