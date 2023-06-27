packer {
  required_plugins {
    parallels = {
      version = ">= 1.0.1"
      source  = "github.com/hashicorp/parallels"
    }
  }
}

source "parallels-iso" "nixos" {
  boot_command           = ["echo -e 'root\\nroot' | sudo passwd root", "<enter>"]
  boot_wait              = "30s"
  cpus                   = "2"
  disk_size              = "81920"
  guest_os_type          = "debian"
  iso_checksum           = "d43b34629140dadeb8d721e219f9835f15251978b075f41a25da9ee7f884f895"
  iso_urls               = ["https://channels.nixos.org/nixos-23.05/latest-nixos-minimal-x86_64-linux.iso"]
  memory                 = "4096"
  parallels_tools_mode   = "disable"
  shutdown_command       = "shutdown"
  ssh_password           = "root"
  ssh_port               = "22"
  ssh_username           = "root"
  ssh_wait_timeout       = "1800s"
  vm_name                = "nixos-base"
}

build {
  name    = "nixos-base"
  
  sources = [
    "source.parallels-iso.nixos"
  ]

  provisioner "shell" {
    inline = [
      "parted /dev/sda --script -- mklabel msdos",
      "parted /dev/sda --script -- mkpart primary 1MiB -8GiB",
      "mkfs.ext4 -L nixos /dev/sda1",
      "sleep 5",
      "mount /dev/disk/by-label/nixos /mnt",
      "mkdir -p /mnt/etc/nixos"
    ]
  }

  provisioner "file" {
    source = "scripts/configuration.nix"
    destination = "/mnt/etc/nixos/configuration.nix"
  }

  provisioner "file" {
    source = "scripts/hardware-configuration.nix"
    destination = "/mnt/etc/nixos/hardware-configuration.nix"
  }

  provisioner "shell" {
    inline = ["nixos-install"]
  }

  post-processors {
    post-processor "vagrant" {
      compression_level = "1"
      output            = "nixos.box"
    }
  }
}
