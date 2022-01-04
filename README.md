# Orchard

My local network, managed by Nix.

## Troubleshooting

### Setting up `sops` `age` keys on macOS

```
$ mkdir -p ~/Library/Application\ Support/sops/age
$ age-keygen -o ~/Library/Application\ Support/sops/age/keys.txt
```

This will output a public key to add to `.sops.yaml`. Regenerate the `secrets.yaml` file with:

```
$ sops updatekeys secrets.yaml
```

### Adding machine `age` key for `sops`

Try either of these options:

```
$ nixops ssh MACHINE_NAME -- "cat /etc/ssh/ssh_host_ed25519_key.pub" | ssh-to-age
$ ssh-keyscan MACHINE_IP | ssh-to-age
```

This will output a public key to add to `.sops.yaml`. Regenerate the `secrets.yaml` file with:

```
$ sops updatekeys secrets.yaml
```

### Machine does not have `/etc/ssh/ssh_hot_ed25519_key.pub`

It's possible that a VM won't have the public key needed for `sops`. SSH into the machine and run:

```
$ ssh-keygen -t ed25519 -C "ethan.turkeltaub+orchard-computer@hey.com"
```

### Unable to SSH into to VirtualBox VM

Run the following to set up the networking properly:

```
$ VBoxManage hostonlyif create
$ VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1
$ VBoxManage dhcpserver remove --netname HostInterfaceNetworking-vboxnet0
$ VBoxManage dhcpserver add --ifname vboxnet0 --ip 192.168.56.1 --netmask 255.255.255.0 --lowerip 192.168.56.100 --upperip 192.168.56.200
$ VBoxManage dhcpserver modify --ifname vboxnet0 --enable
```
