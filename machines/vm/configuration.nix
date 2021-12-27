{ config, pkgs, resources, ... }: {
  deployment = {
    targetEnv = "virtualbox";
    virtualbox = {
      memorySize = 2048;
      headless = true;
    };
  };

  orchard = { services = { tailscale = { enable = false; }; }; };
}
