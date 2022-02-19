{ config, lib, pkgs, ... }:

with lib;

let cfg = config.orchard.services.tinc;
in {
  options.orchard.services.tinc = {
    enable = mkEnableOption "Enable Tinc VPN";

    network = mkOption {
      type = types.submodule {
        options = { name = mkOption { type = types.str; }; };
      };
    };

    host = mkOption {
      type = types.submodule {
        options = {
          name = mkOption { type = types.str; };
          addr = mkOption { type = types.str; };
          mask = mkOption {
            type = types.str;
            default = "255.255.255.0";
          };
          ed25519PrivateKeyPath = mkOption { type = types.str; };
          privateKeyPath = mkOption { type = types.str; };
        };
      };
    };

    # hosts = mkOption {
    #   type = types.listOf (types.submodule {
    #     options = {
    #       name = mkOption { type = types.str; };
    #       publicAddr = mkOption { type = types.str; };
    #       addr = mkOption { type = types.str; };
    #       ed25519PublicKey = mkOption { type = types.str; };
    #       publicKey = mkOption { type = types.lines; };
    #     };
    #   });
    # };
    hosts = mkOption {
      type = types.attrs;
      default = { };
    };
  };

  config = mkIf cfg.enable {
    networking.interfaces."tinc.${cfg.network.name}".ipv4.addresses = [{
      address = cfg.host.addr;
      prefixLength = 24;
    }];

    networking.firewall.allowedTCPPorts = [ 655 ];
    networking.firewall.allowedUDPPorts = [ 655 ];

    services.tinc.networks.${cfg.network.name} = {
      name = cfg.host.name;
      debugLevel = 3;
      chroot = false;
      interfaceType = "tap";
      extraConfig = ''
        # Keys
        Ed25519PrivateKeyFile = ${cfg.host.ed25519PrivateKeyPath}
        PrivateKeyFile = ${cfg.host.privateKeyPath}
      '';
      hosts = cfg.hosts;
    };
  };
}
