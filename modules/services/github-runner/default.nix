{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.github-runner;
in {
  options.orchard.services.github-runner = {
    enable = mkEnableOption "Enable the GitHub Actions runner";
    url = mkOption { type = types.str; };
    tokenFile = mkOption { type = types.path; };
  };

  config = mkIf cfg.enable {
    services.github-runner = {
      inherit (cfg) enable url tokenFile;
      package = pkgs.unstable.github-runner;
    };
  };
}
