{ config, pkgs, lib, ... }: {
  services.qemuGuest.enable = true;

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
}
