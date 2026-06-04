{ lib, ... }:
{
  # WARNING! Use the disk layout as defined in /hosts/disk-config.nix, or else
  # this will possibly break the system!

  # Delete root and back it up for 30 days
  boot.initrd.postResumeCommands = lib.mkAfter ''
    mkdir /btrfs_tmp
    mount /dev/disk/by-partlabel/disk-main-root /btrfs_tmp
    if [[ -e /btrfs_tmp/root ]]; then
      mkdir -p /btrfs_tmp/old_roots
      timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
      mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
    fi

    delete_subvolume_recursively() {
      IFS=$'\n'
      for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
        delete_subvolume_recursively "/btrfs_tmp/$i"
      done
      btrfs subvolume delete "$1"
    }

    for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
      delete_subvolume_recursively "$i"
    done

    btrfs subvolume create /btrfs_tmp/root
    umount /btrfs_tmp
  '';

  # boot.initrd.systemd = {
  #   enable = true;
  #   services.impermanence-btrfs-rolling-root = {
  #     description = "Archiving existing BTRFS root subvolume and creating a fresh one";

  #     unitConfig.DefaultDependencies = false;
  #     serviceConfig.Type = "oneshot";

  #     requiredBy = [ "initrd.target" ];
  #     before = [ "sysroot.mount" ];
  #     requires = [ "initrd-root-device.target" ];
  #     after = [
  #       "initrd-root-device.target"
  #       "local-fs-pre.target"
  #     ];

  #     script = ''
  #       # Ensure the temporary mount point exists
  #       ${pkgs.coreutils}/bin/mkdir -p /btrfs_tmp

  #       # MOUNT: Using your correct partlabel path
  #       mount /dev/disk/by-partlabel/disk-main-root /btrfs_tmp

  #       # If a root subvolume exists, archive it with a timestamp
  #       if [[ -e /btrfs_tmp/root ]]; then
  #           ${pkgs.coreutils}/bin/mkdir -p /btrfs_tmp/old_roots
  #           timestamp=$(${pkgs.coreutils}/bin/date --date="@$(${pkgs.coreutils}/bin/stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%d_%H:%M:%S")
  #           ${pkgs.coreutils}/bin/mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
  #       fi

  #       # Function to recursively delete older subvolumes
  #       delete_subvolume_recursively() {
  #           IFS=$'\n'
  #           for i in $(${pkgs.btrfs-progs}/bin/btrfs subvolume list -o "$1" | ${pkgs.coreutils}/bin/cut -f 9- -d ' '); do
  #               delete_subvolume_recursively "/btrfs_tmp/$i"
  #           done
  #           ${pkgs.btrfs-progs}/bin/btrfs subvolume delete "$1"
  #       }

  #       # Clean up old roots older than 30 days
  #       for i in $(${pkgs.findutils}/bin/find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
  #           delete_subvolume_recursively "$i"
  #       done

  #       # Create a pristine root subvolume for the new boot
  #       ${pkgs.btrfs-progs}/bin/btrfs subvolume create /btrfs_tmp/root

  #       # Clean up
  #       umount /btrfs_tmp
  #     '';
  #   };
  # };

  # Use /persist as the persistence root, matching Disko's mountpoint
  environment.persistence."/nix/persist" = {
    hideMounts = true;
    directories = [
      "/etc" # System configuration (Keep this here for persistence via bind-mount)
      "/var/lib/nixos"
      "/var/lib/mysql"
      "/var/spool" # Mail queues, cron jobs
      "/var/log"
      "/srv" # Web server data, etc.
      "/root"
    ];
    files = [
    ];
  };
}
