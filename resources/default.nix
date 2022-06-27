let
  awsConfig = import ../config/aws.nix;
  inherit (awsConfig) region;
in {
  ec2KeyPairs = { deployment-key = { inherit region; }; };

  ec2SecurityGroups = let
    mkRule = { protocol ? "tcp", port, sourceIp ? "0.0.0.0/0" }: {
      inherit protocol sourceIp;
      fromPort = port;
      toPort = port;
    };
    ssh = mkRule { port = 22; };
    nebula = mkRule {
      protocol = "udp";
      port = 4242;
    };
    loki = mkRule { port = 3100; };
    http = mkRule { port = 80; };
    https = mkRule { port = 443; };
    prometheus-node-exporter = mkRule { port = 9002; };
    prometheus-nginx-exporter = mkRule { port = 9113; };
    mosh = {
      protocol = "udp";
      fromPort = 60000;
      toPort = 61000;
      sourceIp = "0.0.0.0/0";
    };
    wireguard = {
      protocol = "udp";
      fromPort = 51821;
      toPort = 51899;
      sourceIp = "0.0.0.0/0";
    };
  in {
    monitor-security-group = { resources, ... }: {
      inherit region;
      description = "Security group for monitor.orchard.computer";
      rules = [
        ssh
        mosh
        nebula
        loki
        http
        https
        prometheus-node-exporter
        prometheus-nginx-exporter
      ];
    };

    matrix-security-group = { resources, ... }: {
      inherit region;
      description = "Security group for matrix.orchard.computer";
      rules = [
        ssh
        mosh
        nebula
        http
        https
        prometheus-node-exporter
        prometheus-nginx-exporter
      ];
    };

    portal-security-group = { resources, ... }: {
      inherit region;
      description = "Security group for portal.orchard.computer";
      rules = [
        ssh
        mosh
        nebula
        http
        https
        prometheus-node-exporter
        prometheus-nginx-exporter
        wireguard
      ];
    };
  };

  # elasticFileSystems = { matrix-elastic-storage = { inherit region; }; };

  # elasticFileSystemMountTargets = {
  #   matrix-elastic-storage-mount = { resources, ... }: {
  #     inherit region subnet;
  #     fileSystem = resources.elasticFileSystems.matrix-elastic-storage;
  #     securityGroups = [ "default" ];
  #   };
  # };

  elasticIPs = {
    monitor-elastic-ip = { inherit region; };

    matrix-elastic-ip = { inherit region; };

    portal-elastic-ip = { inherit region; };
  };

  route53HostedZones = {
    orchard-computer = {
      name = "orchard.computer.";
      comment = "Hosted zone for orchard.computer";
    };

    e10-land = {
      name = "e10.land";
      comment = "Hosted zone for e10.land";
    };
  };

  route53RecordSets = {
    e10-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.e10-land;
      domainName = "e10.land.";
      ttl = 15;
      recordValues = [ resources.machines.matrix ];
    };

    headscale-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "headscale.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.portal ];
    };

    monitor-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "monitor.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.monitor ];
    };

    grafana-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "grafana.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.monitor ];
    };

    gateway-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "gateway.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.gateway.networking.publicIPv4 ];
    };

    matrix-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "matrix.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.matrix ];
    };

    filebrowser-e10-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.e10-land;
      domainName = "filebrowser.e10.land.";
      ttl = 15;
      recordValues = [ resources.machines.matrix ];
    };

    builder-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "builder.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.matrix ];
    };

    sonarr-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "sonarr.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.gateway.networking.publicIPv4 ];
    };

    radarr-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "radarr.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.gateway.networking.publicIPv4 ];
    };

    nzbget-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "nzbget.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.gateway.networking.publicIPv4 ];
    };

    prowlarr-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "prowlarr.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.gateway.networking.publicIPv4 ];
    };

    overseerr-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "overseerr.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.portal ];
    };

    tautulli-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "tautulli.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.gateway.networking.publicIPv4 ];
    };

    sabnzbd-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "sabnzbd.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.gateway.networking.publicIPv4 ];
    };

    metrics-satan-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "metrics.satan.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.gateway.networking.publicIPv4 ];
    };

    pve-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "pve.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.gateway.networking.publicIPv4 ];
    };

    plex-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "plex.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.gateway.networking.publicIPv4 ];
    };

    jellyfin-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "jellyfin.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.gateway.networking.publicIPv4 ];
    };

    smokeping-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "smokeping.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.gateway.networking.publicIPv4 ];
    };

    feeds-record-set = { resources, ... }: {
      zoneId = resources.route53HostedZones.orchard-computer;
      domainName = "feeds.orchard.computer.";
      ttl = 15;
      recordValues = [ resources.machines.matrix ];
    };
  };

  s3Buckets = let
    glacierLifeCycleConfig = ''
      {
        "Rules": [
           {
             "Status": "Enabled",
             "Prefix": "",
             "Transitions": [
               {
                 "Days": 30,
                 "StorageClass": "GLACIER"
               }
             ],
             "ID": "Glacier",
             "AbortIncompleteMultipartUpload":
               {
                 "DaysAfterInitiation": 7
               }
           }
        ]
      }
    '';
  in {
    errata-backups-bucket = {
      inherit region;
      name = "orchard-errata-backups";
      versioning = "Suspended";
      lifeCycle = glacierLifeCycleConfig;
    };

    htpc-backups-bucket = {
      inherit region;
      name = "orchard-htpc-backups";
      versioning = "Suspended";
      lifeCycle = glacierLifeCycleConfig;
    };

    gateway-backups-bucket = {
      inherit region;
      name = "orchard-gateway-backups";
      versioning = "Suspended";
      lifeCycle = glacierLifeCycleConfig;
    };

    matrix-backups-bucket = {
      inherit region;
      name = "orchard-matrix-backups";
      versioning = "Suspended";
      lifeCycle = glacierLifeCycleConfig;
    };

    monitor-backups-bucket = {
      inherit region;
      name = "orchard-monitor-backups";
      versioning = "Suspended";
      lifeCycle = glacierLifeCycleConfig;
    };
  };
}
