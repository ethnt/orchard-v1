{ config, pkgs, resources, nodes, ... }: {
  deployment = { targetHost = "192.168.1.43"; };

  imports = [ ../qemu.nix ./hardware-configuration.nix ];

  sops = {
    secrets = {
      nebula_host_key = { sopsFile = ./secrets.yaml; };
      nebula_host_cert = { sopsFile = ./secrets.yaml; };
      tinc_ed25519_private_key = { sopsFile = ./secrets.yaml; };
      tinc_private_key = { sopsFile = ./secrets.yaml; };
    };
  };

  # TODO: Make this not manual
  networking.publicIPv4 = "74.65.199.203";

  orchard = {
    services = {
      fail2ban = {
        enable = true;
        allowlist = [
          "127.0.0.0/8"
          "10.0.0.0/8"
          "100.0.0.0/8"
          "172.16.0.0/12"
          "192.168.0.0/16"
          "8.8.8.8"
        ];
      };

      nebula = {
        enable = true;
        host = {
          addr = "10.10.10.1";
          isLighthouse = true;
          keyPath = config.sops.secrets.nebula_host_key.path;
          certPath = config.sops.secrets.nebula_host_cert.path;
        };
      };

      tinc = {
        enable = true;
        network = { name = "orchard"; };
        host = {
          name = "gateway";
          addr = "10.1.1.1";
          mask = "255.255.255.0";
          ed25519PrivateKeyPath =
            config.sops.secrets.tinc_ed25519_private_key.path;
          privateKeyPath = config.sops.secrets.tinc_private_key.path;
        };
        hosts = {
          gateway = ''
            Address = 74.65.199.203
            Subnet = 10.1.1.1
            Ed25519PublicKey = hqNmLh3gIx5L87CYH1vu6zjYTOpF1YhD95Ll/1myj/C
            -----BEGIN RSA PUBLIC KEY-----
            MIICCgKCAgEAvBz3Qogn8lpPOW9vAA3j2e2iESe1a+ikdw8GM2mJAZueis/F/1aA
            ExLkWzrcIQwrs0zd0e4FhtvGGwERaAO39yH0H1x/kFBY3rin4QhvtdtZRTAhKMIN
            vFgY+cP+S/Hi7JQEVKbTGS9tBE6iLNpgmn0VAHoYYOSRoziOfaQW5jrvxKPv/ySA
            Klqdf4uwQZkgB1GLcLAxSrdG1gBa6NVVJF96GF4mTfJIOOEn7r1qMDGqEgG8+5Mc
            q09mmaSg6j/kjgwOAhh6L69ZKZLWguTWrqdby5kbzFy5V5xRLD/EDjCqKr2oyb2w
            WZ8zwEmo+L+msIzLV427DFl834JIkIhhNafNtj3as/Ty/x0Em5JTuK6UdlISdRoR
            NPIiVTVKK/y+dbmxeKleSrqYG3yvfT7Dr42QXjOpwFAPuf5Lyil2J3khALoN14np
            f/za4pmVn0da7wIyLMasf9+Wr76IbBZduPwF9KvUHzhJDRkmAr2/XdhiecVP8W08
            AJO8KHUwnxwseV9OxPlT+46bzE0bne96/kSXvHwalgtqDPdufdnL/tXClx+AYd3f
            3RofOYn1AMj740f09fpY1m5J++UtS1TzTJqKASeGV7C/KEmOIICB+Uf944+MJMdg
            rGrFKxc5wfNEN68O2oXVSuwPgcIzKOxpr0j/y9uaLew2i9CwOCBTPtkCAwEAAQ==
            -----END RSA PUBLIC KEY-----
          '';

          htpc = ''
            Address = 192.168.1.44
            Subnet = 10.1.1.2
            Ed25519PublicKey = 1j0EzZreAYQa1W2bJRc0n6IJfKsUiXV7yNqhURlMjUI
            -----BEGIN RSA PUBLIC KEY-----
            MIICCgKCAgEA1PwIFN5OQKuKjAYhT/GGpXfpDUWo4LTNjbpoW6iap4R54XxaP9WH
            qdG3hTIhrQuJSikfU/+LJ7zOQtNFJ8qcjKHborNL9kRBljqxe7f7jQdsfIQYbtdk
            mfxXAutYc+G3HIKM19tvZSlK05B6qLW3ny6CWCBw/T/RpYvQtbJWuHSiG4TqdbXE
            mjHK2dl00JRM0Ko7qOa9x1XeV8bn20dvYCtgJDZJ6+FM6BKFh7l9bXXcgcGIyOTl
            cjG78OkNIXQiq6lR/SYnDXvRE3Xa2Kbldu6aQnkRXnA1aXDBpKTgfFWFF3BegDgL
            OQY3IzgBprcfzcdbWViIj34w8SWo9RWlv16YYhJ4J9jjp5MFgohywOHNSHgPdnQw
            462jT+3iFhkYfLamJj9w9sGsmrvWzCj2xSS/WuZFUZR//GEREmKpEt+pk9zLwSuI
            NSjFx2l6mXVKS+31irgPv5kwKtkJLAHItDXHx657NSvAPWMO7zanwHk7Dnknc4px
            PF1eiCTtUBoO+hpwYzH27HkpDAi4ZQNfmTPELZ62kR79pPuaQk7QMuh3Mj0NSeQX
            zhrEmAmD7Rh6ZC1KflJ2X9fRv1UqmqXTppGRAFnylls6OpzCkbIRF0sn3HHtLrPi
            XnRe1eRo/gdMVK4z9yCq/+tA4timcxnovnuQze7gyuoekgXjuoO7+lMCAwEAAQ==
            -----END RSA PUBLIC KEY-----
          '';

          monitor = ''
            Address = 52.15.121.207
            Subnet = 10.1.1.4
            Ed25519PublicKey = fzAAgvd9iJ0yoXj00hTQbBl5gJVtaqddxbuXgZs28CE
            -----BEGIN RSA PUBLIC KEY-----
            MIICCgKCAgEAzeU6xvryPEew9ISBPL0OuyM3oIclb6S961uf7CLZoXp2CskZVXPq
            zaJz/MjLcmCq4dQygoRMht4Tky3YW1GRaa8L4D/FFsrCWAU91Qleb6MXI5Z7fHaz
            KXx1UupZ+UBAxuYr8u81F6SU3oJ7WTlFcDEyhWVccy6O345fGehXy33bnSGDwROG
            Sq05VDmo+0nRasLETLHmiGLAAwj3rZg6lmtL9Ari3oGdUu14BUJX49wfjMKcA4In
            GNWcb9/oWwC/B57vCKyyBRFk61UmKK1Zly5BhGgvprEfCL0yAm4/anC6uZvINJy7
            QM7yxwECZ37gthqqJiyL4/0zOVjf7IUlTR83JSW1Whr+mVBvlr8o5hnkuv6B1t6x
            6LsEtOX/nCJopStPhmNdhlg4yjV7j2/aUAe2JnEhA/YzEfcSwYJMJD2VjXUlPwKD
            vLyQMcuuEfSocyMscnlevLIfi5efkQyEEBptIyItW/Igl3dA0OfnhAq7rsZYeNR5
            Ur5g0jqZ2GTQ5t+LHaLeX/tDPxuhjRBgJwT1fbX0MiS75jlj50CKFk+1VWnJ7b6r
            V1AJOv9TpQWgDKcTlKlTU5ie5Uf6Ay3x//pe0xwd5cJccUKM52QIX9oet5Dsi7pw
            AXuIjU1sTkffBMd1MXHxLJgLGJeKHbWA72qBkGA2uu3SEtiikA4j6rcCAwEAAQ==
            -----END RSA PUBLIC KEY-----
          '';
        };
      };

      nginx = {
        enable = true;
        acme = { email = "admin@orchard.computer"; };
        virtualHosts = {
          "sonarr.orchard.computer" = {
            http2 = true;

            addSSL = true;
            enableACME = true;

            locations."/" = {
              proxyPass =
                "http://${nodes.htpc.config.orchard.services.nebula.host.addr}:${
                  toString nodes.htpc.config.orchard.services.sonarr.port
                }";
            };
          };

          "radarr.orchard.computer" = {
            http2 = true;

            addSSL = true;
            enableACME = true;

            locations."/" = {
              proxyPass =
                "http://${nodes.htpc.config.orchard.services.nebula.host.addr}:${
                  toString nodes.htpc.config.orchard.services.radarr.port
                }";
            };
          };

          "nzbget.orchard.computer" = {
            http2 = true;

            addSSL = true;
            enableACME = true;

            locations."/" = {
              proxyPass =
                "http://${nodes.htpc.config.orchard.services.nebula.host.addr}:${
                  toString nodes.htpc.config.orchard.services.nzbget.port
                }";
            };
          };

          "plex.orchard.computer" = {
            http2 = true;

            addSSL = true;
            enableACME = true;

            extraConfig = ''
              send_timeout 100m;
              ssl_stapling on;
              ssl_stapling_verify on;
              ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
              ssl_prefer_server_ciphers on;
              ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:ECDHE-RSA-DES-CBC3-SHA:ECDHE-ECDSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA';
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Proto $scheme;
              proxy_set_header Host $server_addr;
              proxy_set_header Referer $server_addr;
              proxy_set_header Origin $server_addr;
              gzip on;
              gzip_vary on;
              gzip_min_length 1000;
              gzip_proxied any;
              gzip_types text/plain text/css text/xml application/xml text/javascript application/x-javascript image/svg+xml;
              gzip_disable "MSIE [1-6]\.";
              client_max_body_size 100M;
              proxy_set_header X-Plex-Client-Identifier $http_x_plex_client_identifier;
              proxy_set_header X-Plex-Device $http_x_plex_device;
              proxy_set_header X-Plex-Device-Name $http_x_plex_device_name;
              proxy_set_header X-Plex-Platform $http_x_plex_platform;
              proxy_set_header X-Plex-Platform-Version $http_x_plex_platform_version;
              proxy_set_header X-Plex-Product $http_x_plex_product;
              proxy_set_header X-Plex-Token $http_x_plex_token;
              proxy_set_header X-Plex-Version $http_x_plex_version;
              proxy_set_header X-Plex-Nocache $http_x_plex_nocache;
              proxy_set_header X-Plex-Provides $http_x_plex_provides;
              proxy_set_header X-Plex-Device-Vendor $http_x_plex_device_vendor;
              proxy_set_header X-Plex-Model $http_x_plex_model;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "upgrade";
              proxy_http_version 1.1;
              proxy_redirect off;
              proxy_buffering off;
            '';

            locations."/" = {
              proxyPass =
                "http://${nodes.htpc.config.orchard.services.nebula.host.addr}:${
                  toString nodes.htpc.config.orchard.services.plex.port
                }";
            };
          };
        };
      };
    };
  };
}
