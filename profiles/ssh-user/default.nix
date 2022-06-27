{ config, pkgs, ... }: {
  users.users.orchard = {
    isNormalUser = true;
    createHome = true;
    hashedPassword =
      "$6$uWdBBHFmu2RqXQYG$if2AOX1aSpykA4uzSB//vr0GHt.Kw00tJOHazAnZUEU5LNcIOF6UyMPDSfH97Fis4DJF6kBmUMmqqxXmMn9hp.";
    shell = pkgs.fish;
    openssh.authorizedKeys.keyFiles = [ ./orchard.pub ];
    extraGroups = [ "wheel" ];
  };
}
