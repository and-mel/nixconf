#!/bin/sh

# ssh-keygen -t ed25519 -f ~/nixos-key/ssh_host_ed25519_key -C "root@<hostname>"
# ADD the resulting public key to secrets.nix
# Command usage: ./deploy.sh root@<ip> <hostname> <ssh-key-directory>
root=$(mktemp -d -p /tmp)
cp --archive --parents ~/nixos $root
mkdir -p $root/etc/
cp -r $3 $root/nix/persist/etc/ssh

printf $root
# printf "if nh home switch -b backup && uwsm check may-start; then\n\texec uwsm start -S hyprland-uwsm.desktop\nfi\n" > $root/home/$(whoami)/.zshrc
nix run github:nix-community/nixos-anywhere -- --flake "/home/$(whoami)/nixos#$2" --extra-files "$root" --chown /home/$(whoami) 1000:100 --generate-hardware-config nixos-generate-config /home/$(whoami)/nixos/hosts/$2/hardware-configuration.nix --target-host $1
rm $root
