# Most of this is lifted from johnae/world:
#   https://github.com/johnae/world/blob/d7d71cbe2c397903357f1db6437f8098f3874bfc/modules/innernet.nix

{ config, lib, pkgs, ... }:

with lib;

let
  inherit (builtins) concatStringsSep length all any filter getAttr listToAttrs;
  inherit (lib) mapAttrsToList;

  innernetServerDatabasePath = "/var/lib/innernet-server";
  innernetServerConfigurationPath = "/etc/innernet-server";
  innernetClientConfigurationPath = "/etc/innernet";

  cfg = config.orchard.services.innernet;
  clientConfigurations = mapAttrsToList (_: v: v) cfg.client;
  serverConfigurations = mapAttrsToList (_: v: v) cfg.server;

  enabledFilter = filter (getAttr "enable");

  enabledClientConfigurations = enabledFilter clientConfigurations;
  enabledServerConfigurations = enabledFilter serverConfigurations;

  enabled =
    (length (enabledClientConfigurations ++ enabledServerConfigurations)) > 0;

  addNetwork = { networkName, cidr, externalEndpoint, listenPort, publicKey
    , privateKeyFile, ... }:
    pkgs.writeShellScript "add-network-${networkName}" ''
      rm -f ${innernetServerConfigurationPath}/${networkName}.conf ${innernetServerDatabasePath}/${networkName}.db

      ${cfg.package}/bin/innernet-server new \
        --network-name "${networkName}" \
        --network-cidr "${cidr}" \
        --external-endpoint "${externalEndpoint}" \
        --listen-port ${toString listenPort} >/dev/null

      PKEY="$(cat ${privateKeyFile})"
      export PKEY

      sed -i "s|private-key =.*|private-key = \"$PKEY\"|g" ${innernetServerConfigurationPath}/${networkName}.conf

      cat <<SQL | ${pkgs.sqlite}/bin/sqlite3 ${innernetServerDatabasePath}/${networkName}.db
       UPDATE peers
       SET public_key = '${publicKey}'
       WHERE name = 'innernet-server';
      SQL
    '';

  addCidr = { networkName, name, cidr, parent }:
    pkgs.writeShellScript "add-cidr-${name}" ''
      ${cfg.package}/bin/innernet-server add-cidr \
        --name "${name}" \
        --cidr "${cidr}" \
        --parent "${parent}" \
        --yes ${networkName} >/dev/null
    '';

  addPeer = { networkName, name, ip, cidr, publicKey, isAdmin ? false }:
    pkgs.writeShellScript "add-cidr-${name}" ''
      trap 'rm -f /tmp/${name}.toml' EXIT

      ${cfg.package}/bin/innernet-server add-peer \
        --name "${name}" \
        --ip "${ip}" \
        --cidr "${cidr}" \
        --admin "${isAdmin}" \
        --save-config /tmp/${name}.toml \
        --yes ${networkName} >/dev/null

      cat << SQL | ${pkgs.sqlite}/bin/sqlite3 ${innernetServerDatabasePath}/${networkName}.db
        UPDATE peers
        SET is_redeemed = 1,
            public_key = '${publicKey}'
        WHERE name = '${name}';
      SQL
    '';

  peersOptions = with lib.types;
    submodule ({ name, ... }: {
      options = {
        name = mkOption {
          type = str;
          default = name;
          description = "The name of the peer";
          example = "hostname-1";
        };
        ip = mkOption {
          type = str;
          description = "The ip of the peer";
          example = "10.100.4.1";
        };
        cidr = mkOption {
          type = str;
          description = "The name of the cidr block this peer belongs to";
        };
        publicKey = mkOption {
          type = str;
          description = "The public key of the peer";
        };
        isAdmin = mkOption {
          type = bool;
          description = "Whether this peer is an admin";
          default = false;
          apply = v: if v then "true" else "false";
        };
      };
    });

  cidrsOptions = with lib.types;
    submodule ({ name, ... }: {
      options = {
        name = mkOption {
          type = str;
          default = name;
          description = "The name of the cidr block";
          example = "humans";
        };
        cidr = mkOption {
          type = str;
          description = "The cidr block";
          example = "10.100.4.0/22";
        };
        parent = mkOption {
          type = str;
          description = "The name of the parent cidr block";
        };
      };
    });

  associationsModule = with lib.types;
    submodule {
      options = {
        leftCidr = mkOption {
          type = cidrsOptions;
          description = "A cidr to associate with another";
        };
        rightCidr = mkOption {
          type = cidrsOptions;
          description = "A cidr to associate with another";
        };
      };
    };

  writeClientCfg = cfg:
    pkgs.writeShellScript
    "innernet-write-client-cfg-${cfg.settings.interface.networkName}" ''
      mkdir -p ${innernetClientConfigurationPath}

      cat << EOF >${innernetClientConfigurationPath}/${cfg.settings.interface.networkName}.conf
        [interface]
        network-name = "${cfg.settings.interface.networkName}"
        address = "${cfg.settings.interface.address}"
        private-key = "$(cat ${cfg.settings.interface.privateKeyFile})"

        [server]
        public-key = "${cfg.settings.server.publicKey}"
        external-endpoint = "${cfg.settings.server.externalEndpoint}"
        internal-endpoint = "${cfg.settings.server.internalEndpoint}"
      EOF
    '';

in {

  options.orchard.services.innernet = with lib.types; {
    package = mkOption {
      type = package;
      default = pkgs.innernet;
      defaultText = "pkgs.innernet";
      description = "The package to use for innernet";
    };
    client = mkOption {
      default = { };
      type = attrsOf (submodule ({ name, ... }: {
        options = {
          enable = mkEnableOption "innernet client daemon for ${name}";
          settings = mkOption {
            type = submodule {
              options = {
                interface = {
                  networkName = mkOption {
                    type = str;
                    default = name;
                    example = "innernet0";
                    description = "The name of the network we're connecting to";
                  };
                  fetchInterval = mkOption {
                    type = int;
                    default = 25;
                    example = "25";
                    description = "How often to refresh peers from server";
                  };
                  address = mkOption {
                    type = str;
                    example = "10.100.0.5/16";
                    description =
                      "The addresss of this peer, the prefix should be that of the network (not the cidr this host is part of)";
                  };
                  privateKeyFile = mkOption {
                    type = path;
                    description = "The path to the private key file";
                    example = "/run/agenix/private-key";
                  };
                };
                server = {
                  publicKey = mkOption {
                    type = str;
                    description = "The public key of the server";
                    example = "wLKnL8rBNdSV7HBeuJLS6inBsqbqEwCexN+6jAbMfxk=";
                  };
                  externalEndpoint = mkOption {
                    type = str;
                    description = "The external endpoint of the server";
                    example = "1.2.3.4:51820";
                  };
                  internalEndpoint = mkOption {
                    type = str;
                    description = "The internal endpoint of the server";
                    example = "10.100.0.1:51820";
                  };
                };
              };
            };
          };
        };
      }));
    };

    server = mkOption {
      default = { };
      type = attrsOf (submodule ({ name, ... }: {
        options = {
          enable = mkEnableOption "innernet server daemon for ${name}";
          settings = mkOption {
            type = submodule {
              options = {
                networkName = mkOption {
                  type = str;
                  default = name;
                  description = "The name of the network";
                  example = "innernet0";
                };
                cidr = mkOption {
                  type = str;
                  description = "The network cidr of the root network";
                  example = "10.100.0.0/16";
                };
                privateKeyFile = mkOption {
                  type = path;
                  description = "The path to the private key file";
                  example = "/run/agenix/server-private-key";
                };
                externalEndpoint = mkOption {
                  type = str;
                  description = "The external endpoint of the server";
                  example = "1.1.1.1:51820";
                };
                internalEndpoint = mkOption {
                  type = str;
                  description = "The internal endpoint of the server";
                  example = "10.100.0.1:51820";
                };
                publicKey = mkOption {
                  type = str;
                  description = "The public key of the server";
                  example = "r5UmbAK0EKXQEI4LLTJYHWGWDraj4jK+EZSyk9KSPQw=";
                };
                listenPort = mkOption {
                  type = port;
                  description = "The server listen port";
                  example = 51820;
                };
                cidrs = mkOption {
                  type = attrsOf cidrsOptions;
                  default = { };
                  description = "The cidrs of this network";
                };
                associations = mkOption {
                  type = listOf associationsModule;
                  default = [ ];
                  description =
                    "The associations between cidrs on this network";
                };
                peers = mkOption {
                  type = attrsOf peersOptions;
                  default = { };
                  description = "The peers of this network";
                };
                openFirewall = mkOption {
                  type = bool;
                  default = false;
                  description =
                    "Whether to open relevant ports in the firewall automatically";
                };
              };
            };
          };
        };
      }));
    };
  };

  config = mkIf enabled {
    boot.kernelModules = [ "wireguard" ];

    networking.wireguard.enable = true;

    networking.firewall = let
      ports = map (server: server.settings.listenPort)
        (filter (server: server.settings.openFirewall)
          enabledServerConfigurations);
    in {
      allowedTCPPorts = ports;
      allowedUDPPorts = ports;
    };

    environment.systemPackages = [ cfg.package ];

    systemd.services = ((listToAttrs (map (server: {
      name = "innernet-server@${server.settings.networkName}";
      value = {
        after = [ "network-online.target" "nss-lookup.target" ];
        wantedBy = [ "multi-user.target" ];

        path = [ pkgs.iproute ];
        environment = { RUST_LOG = "info"; };

        serviceConfig = {
          Restart = "always";
          ExecStartPre = pkgs.writeShellScript
            "innernet-server-pre@${server.settings.networkName}" ''
              ${addNetwork server.settings}

              ${concatStringsSep "\n" (map addCidr (mapAttrsToList
                (_: v: v // { inherit (server.settings) networkName; })
                server.settings.cidrs))}

              ${concatStringsSep "\n" (map addPeer (mapAttrsToList
                (_: v: v // { inherit (server.settings) networkName; })
                server.settings.peers))}
            '';

          ExecStart =
            "${cfg.package}/bin/innernet-server serve ${server.settings.networkName}";
        };
      };
    }) enabledServerConfigurations)) // (listToAttrs (map (client: {
      name = "innernet-client@${client.settings.interface.networkName}";
      value = {
        after = [ "network-online.target" "nss-lookup.target" ];
        wantedBy = [ "multi-user.target" ];

        path = with pkgs; [ iproute ];
        environment = { RUST_LOG = "info"; };

        serviceConfig = {
          Restart = "always";
          ExecStartPre = writeClientCfg client;
          ExecStart =
            "${cfg.package}/bin/innernet up -d --no-write-hosts --interval ${
              toString client.settings.interface.fetchInterval
            } ${client.settings.interface.networkName}";
        };
      };
    }) enabledClientConfigurations)));
  };
}
