{ pkgs, resources, ... }:
let awsDefaults = import ../../config/aws.nix;
in {
  deployment = {
    targetEnv = "ec2";

    ec2 = {
      inherit (awsDefaults) region;
      instanceType = "t3.micro";
      securityGroups = [ resources.ec2SecurityGroups.ssh-security-group ];
      keyPair = resources.ec2KeyPairs.deployment-key;
    };
  };
}
