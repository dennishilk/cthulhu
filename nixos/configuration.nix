{ config, pkgs, ... }:

{
  ########################################
  # Imports
  ########################################
  imports = [
    ./hardware-configuration.nix
  ];

  ########################################
  # Branding
  ########################################
  environment.variables = {
    NIXOS_OS_NAME = "I use NixOS btw";
  };

  ########################################
  # Bootloader
  ########################################
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.systemd-boot.editor = false;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.loader.timeout = 2;
  boot.loader.efi.canTouchEfiVariables = true;

  system.build.label = "Cthulhu – Stable";

  ########################################
  # Always boot into GUI
  ########################################
  systemd.defaultUnit = "graphical.target";

  ########################################
  # Nix & Garbage Collection
  ########################################
  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [ "nix-command" ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  ########################################
  # Kernel (STABLE)
  ########################################
  boot.kernelPackages = pkgs.linuxPackages;
  boot.kernelModules = [ "kvm-amd" ];

  ########################################
  # ZRAM
  ########################################
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };

  ########################################
  # Sysctl
  ########################################
  boot.kernel.sysctl = {
    "vm.swappiness" = 80;
    "vm.vfs_cache_pressure" = 200;
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;
  };

  ########################################
  # Virtualisation (KVM / QEMU / libvirt)
  ########################################
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      swtpm.enable = true;
      ovmf.enable = true;
    };
  };

  virtualisation.spiceUSBRedirection.enable = true;
  services.spice-vdagentd.enable = true;
  programs.virt-manager.enable = true;

  ########################################
  # Cockpit (Web UI – Proxmox-like)
  ########################################
  services.cockpit = {
    enable = true;
    port = 9090;
  };

  ########################################
  # User
  ########################################
  users.users.nebu = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [
      "wheel"
      "video"
      "audio"
      "networkmanager"
      "libvirtd"
      "kvm"
    ];
  };

  ########################################
  # Fish
  ########################################
  programs.fish.enable = true;
  programs.fish.interactiveShellInit = ''
    set -g fish_greeting ""
  '';

  ########################################
  # Network
  ########################################
  networking.hostName = "cthulhu";
  networking.networkmanager.enable = true;
  networking.firewall.trustedInterfaces = [ "virbr0" ];

  ########################################
  # Time & Locale
  ########################################
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "de_DE.UTF-8";
  console.keyMap = "de";

  ########################################
  # X11 + KDE Plasma 6 (X11 only)
  ########################################
  services.xserver.enable = true;
  services.xserver.xkb.layout = "de";
  services.xserver.videoDrivers = [ "nvidia" ];

  ########################################
  # SDDM + Plasma X11
  ########################################
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = false;
  services.displayManager.defaultSession = "plasmax11";
  services.desktopManager.plasma6.enable = true;

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    breeze-icons
  ];

  ########################################
  # NVIDIA (STABLE)
  ########################################
  nixpkgs.config.allowUnfree = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    open = false;
    modesetting.enable = true;
    powerManagement.enable = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  ########################################
  # Audio – PipeWire
  ########################################
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.pipewire.wireplumber.enable = true;
  services.pulseaudio.enable = false;

  ########################################
  # Desktop Services
  ########################################
  services.dbus.enable = true;
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  ########################################
  # Flatpak + Portal
  ########################################
  services.flatpak.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
  };

  ########################################
  # Fonts
  ########################################
  fonts.fontconfig.enable = true;
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    noto-fonts-emoji
  ];

  ########################################
  # GTK Theme
  ########################################
  environment.sessionVariables = {
    GTK_THEME = "Tokyonight-Dark";
    GTK_ICON_THEME = "Papirus-Dark";
  };

  ########################################
  # System Packages
  ########################################
  environment.systemPackages = with pkgs; [

    # CLI
    fish curl wget git unzip openssl tree tmux fastfetch btop iotop hashcat

    # Media
    zoom-us ffmpeg-full sox imagemagick ffmpegthumbnailer poppler_utils yt-dlp

    # Dev
    jdk21 nodejs_20 parted

    # Audio / Input
    pamixer pavucontrol xbindkeys

    # X11 helpers
    wmctrl xorg.xrandr xorg.xev xterm

    # GUI
    kitty typora xfce.mousepad file-roller
    eog dconf gnome-disk-utility

    firefox google-chrome
    kdePackages.kdenlive
    vlc

    (pkgs.obs-studio.override {
      cudaSupport = true;
      ffmpeg = pkgs.ffmpeg-full;
    })

    # Gaming
    steam wowup-cf gamemode mangohud
    libva-utils nvidia-vaapi-driver vulkan-tools

    # VM tools
    cockpit
    virt-viewer
    spice spice-gtk spice-protocol
    dnsmasq bridge-utils
  ];

  ########################################
  # Samba (Retro)
  ########################################
  services.samba.enable = true;

  services.samba.settings = {
    global = {
      workgroup = "WORKGROUP";
      serverString = "Cthulhu Retro Server";
      security = "user";
      "server min protocol" = "NT1";
      "client min protocol" = "NT1";
      "ntlm auth" = true;
      "lanman auth" = true;
      "map to guest" = "Bad User";
    };

    retro = {
      path = "/home/nebu/retro-share";
      browseable = true;
      writable = true;
      "guest ok" = true;
      "create mask" = "0777";
      "directory mask" = "0777";
    };
  };

  systemd.tmpfiles.rules = [
    "d /home/nebu/retro-share 0777 nebu nebu -"
  ];

  ########################################
  # Game Drives
  ########################################
  fileSystems."/mnt/Games.Vol1" = {
    device = "/dev/disk/by-label/Games.Vol1";
    fsType = "ext4";
    options = [ "noatime" "nofail" "x-systemd.device-timeout=1s" ];
  };

  fileSystems."/mnt/Games.Vol2" = {
    device = "/dev/disk/by-label/Games.Vol2";
    fsType = "ext4";
    options = [ "noatime" "nofail" "x-systemd.device-timeout=1s" ];
  };

  ########################################
  # Homelab NVMe Data Disk
  ########################################
  fileSystems."/mnt/Homelab" = {
    device = "/dev/disk/by-label/homelab";
    fsType = "ext4";
    options = [ "noatime" "nofail" "x-systemd.device-timeout=1s" ];
  };


  ########################################
  # State Version
  ########################################
  system.stateVersion = "25.05";
}



  
