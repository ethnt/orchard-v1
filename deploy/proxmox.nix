{
  terraform = {
    required_providers = {
      proxmox = {
        source = "telmate/proxmox";
        version = "2.9.10";
      };
    };
  };

  provider.proxmox = {
    pm_tls_insecure = true;
    pm_api_url = "https://192.168.1.42:8006/api2/json";
    pm_user = "root@pam";
    # pm_password = "password";
  };

  resource.proxmox_vm_qemu.errata = {
    name = "errata";
    target_node = "pve";
    bios = "ovmf";
    agent = 1;
    full_clone = false;
    boot = "order=scsi0;net0";
    cores = 2;
    memory = 4098;
    onboot = true;
    automatic_reboot = true;
    oncreate = true;
    cpu = "kvm64";

    network = {
      bridge = "vmbr0";
      firewall = true;
      link_down = false;
      macaddr = "AA:19:B8:92:3C:2B";
      model = "virtio";
      mtu = 0;
      queues = 0;
      rate = 0;
      tag = -1;
    };

    disk = {
      backup = 0;
      cache = "none";
      discard = "on";
      file = "vm-102-disk-0";
      format = "raw";
      iothread = 1;
      mbps = 0;
      mbps_rd = 0;
      mbps_rd_max = 0;
      mbps_wr = 0;
      mbps_wr_max = 0;
      replicate = 0;
      size = "32G";
      slot = 0;
      ssd = 0;
      storage = "local-lvm";
      # storage_type = "lvmthin";
      type = "scsi";
      volume = "local-lvm:vm-102-disk-0";
    };

    timeouts = { };
  };
}
