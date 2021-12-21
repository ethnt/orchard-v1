let awsDefaults = import ../config/aws.nix;
in {
  ec2KeyPairs = { deployment-key = { inherit (awsDefaults) region; }; };

  ec2SecurityGroups = {
    ssh-security-group = {
      inherit (awsDefaults) region;

      description = "Security group for SSH access";
      rules = [{
        fromPort = 22;
        toPort = 22;
        sourceIp = "0.0.0.0/0";
      }];
    };
  };
}
