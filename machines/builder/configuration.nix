{ config, pkgs, resources, ... }:
let awsConfig = import ../../config/aws.nix;
in {
  deployment = {
    targetEnv = "ec2";
    ec2 = {
      inherit (awsConfig) region;

      instanceType = "t3.medium";
      keyPair = resources.ec2KeyPairs.deployment-key;
      securityGroups = [ resources.ec2SecurityGroups.ssh-security-group ];
      ebsBoot = true;
      ebsInitialRootDiskSize = 50;
    };

    keys = { ssh-builder-key = { keyFile = ./keys/builder.pub; }; };
  };

  users.extraUsers.test = {
    createHome = true;
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    group = "users";
    password = "test";
  };

  orchard = {
    services = {
      remote-builder = {
        enable = true;
        emulatedSystems = [ "aarch64-linux" ];
        buildUserKey =
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDtFmlz8ncuc4bCQA5r8jFMUGL7vmUZ2aNslOSiqVhk1/0kyj3CcP4DAGWokYQIDYSAnISVwmOhND3Tx/zGDFZT3PFwa8ZnKRaPmYumhE9UGmi25DRdCaECbICWscCm3Sw9WIBN+5N78LFwsGvrwmjuBCW6O206Q3WeQjBFrZFNIpQLvNvqDISlMNlEHD1ozylIWJzc8MJu3g+jpuKpOooihnhSAmYoVim8IHYvEx956xRocIGWB8kqpwJ3+0LzXBZeuC8mwEJN6Kqb0pwd7n0+8duyyeGsq/t6rRkCBJ/lvHvxMj8mYr0ZlImow9OEZ9+gPmgAhy8vmlFP0cYcIHeWQL8kN4qU+z/T692Zyvi+dZSy7iEmRzVRcK2Wjj8xUx86mrrxiZAPWQRNYg01wkLEha6xegbq/w7AhoePkdmJKHhaRnrAV8uaQCHrB7P01YQPY6mThE7d2UStDAEkl4UjE3KM5/l5BLtcnM8XeL0aTr9ztAk4svte4LjiyXzgH3M= ethan@eMac.local";
      };
    };
  };
}
