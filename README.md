# Orchard

My local network, managed by Nix.

## Troubleshooting

### Unable to SSH into to VirtualBox VM

Run the following to set up the networking properly:

```
$ VBoxManage hostonlyif create
$ VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1
$ VBoxManage dhcpserver remove --netname HostInterfaceNetworking-vboxnet0
$ VBoxManage dhcpserver add --ifname vboxnet0 --ip 192.168.56.1 --netmask 255.255.255.0 --lowerip 192.168.56.100 --upperip 192.168.56.200
$ VBoxManage dhcpserver modify --ifname vboxnet0 --enable
```
