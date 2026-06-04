{
  device ? throw "Set this to your device, e.g. /dev/sda",
  ...
}:
{
  fileSystems."/nix".neededForBoot = true;

  disko.devices.nodev = {
    "/" = {
      fsType = "tmpfs";
      mountOptions = [
        "size=1G"
        "mode=755"
      ];
    };
  };

  disko.devices.disk.main = {
    inherit device; # MAKE SURE TOO SELECT CORRECT DISK HERE
    type = "disk";

    content.type = "gpt";

    content.partitions.boot = {
      name = "boot";
      size = "1M";
      type = "EF02";
    };

    content.partitions.esp = {
      name = "ESP";
      size = "1G";
      type = "EF00";

      content = {
        type = "filesystem";
        format = "vfat";
        mountpoint = "/boot";
      };
    };

    content.partitions.swap = {
      size = "4G";

      content = {
        type = "swap";
        resumeDevice = true;
      };
    };

    content.partitions.root = {
      name = "root";
      size = "100%";

      content = {
        type = "btrfs";
        extraArgs = [ "-f" ];

        subvolumes = {
          "/home" = {
            mountOptions = [
              "subvol=home"
              "noatime"
            ];
            mountpoint = "/home";
          };

          "/nix" = {
            mountOptions = [
              "subvol=nix"
              "noatime"
            ];
            mountpoint = "/nix";
          };
        };
      };
    };
  };
}
