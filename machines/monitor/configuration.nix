{ config, lib, pkgs, resources, nodes, ... }:
let aws = import ../../config/aws.nix;
in {
  deployment = {
    targetEnv = "ec2";
    ec2 = {
      inherit (aws) region;

      instanceType = "t3.medium";
      keyPair = resources.ec2KeyPairs.deployment-key;
      securityGroups = [ resources.ec2SecurityGroups.monitor-security-group ];
      ebsBoot = true;
      ebsInitialRootDiskSize = 128;
    };
  };

  sops = {
    secrets = {
      nebula_host_key = { sopsFile = ./secrets.yaml; };
      nebula_host_cert = { sopsFile = ./secrets.yaml; };
      tinc_ed25519_private_key = { sopsFile = ./secrets.yaml; };
      tinc_private_key = { sopsFile = ./secrets.yaml; };
    };
  };

  orchard = {
    services = {
      nebula = {
        enable = true;
        network = {
          lighthouses = [ "10.10.10.1" ];
          staticHostMap = {
            "10.10.10.1" =
              [ "${nodes.gateway.config.networking.publicIPv4}:4242" ];
            "10.10.10.2" =
              [ "${nodes.gateway.config.networking.publicIPv4}:4343" ];
          };
        };
        host = {
          addr = "10.10.10.4";
          keyPath = config.sops.secrets.nebula_host_key.path;
          certPath = config.sops.secrets.nebula_host_cert.path;
        };
      };

      tinc = {
        enable = true;
        network = { name = "orchard"; };
        host = {
          name = "monitor";
          addr = "10.1.1.4";
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
    };
  };
}
