{ config, pkgs, ... }:

{
  ########################################
  # Imports
  ########################################
  imports = [ ./hardware-configuration.nix ];

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

  # Current NixOS uses system.nixos.label for boot/build labels.
  # Spaces and the old en-dash label are not valid here.
  system.nixos.label = "Cthulhu-Radeon";
  systemd.defaultUnit = "graphical.target";

  ########################################
  # Nix
  ########################################
  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [ "nix-command" ];
  };

  # Intentionally no automatic garbage collection.
  # Keep rollback generations until we deliberately clean them up.

  ########################################
  # Kernel
  ########################################
  boot.kernelPackages = pkgs.linuxPackages_latest;

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
  # Virtualisation
  ########################################
  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.qemu.swtpm.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;

  programs.virt-manager.enable = true;

  ########################################
  # User / Shell
  ########################################
  programs.fish.enable = true;

  users.users.nebu = {
    isNormalUser = true;
    description = "nebu";
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
  # Network
  ########################################
  networking.hostName = "cthulhu";
  networking.networkmanager.enable = true;

  ########################################
  # Firewall
  ########################################
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];
    trustedInterfaces = [ "virbr0" ];
  };

  ########################################
  # Time & Locale
  ########################################
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "de_DE.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  console.keyMap = "de";

  ########################################
  # Display / KDE Plasma
  ########################################
  services.xserver.enable = true;
  services.xserver.xkb = {
    layout = "de";
    variant = "";
  };

  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Plasma 6 itself uses Wayland by default. Keep SDDM on its stable default
  # instead of enabling SDDM's still-experimental Wayland compositor.

  ########################################
  # AMD / Mesa Graphics
  ########################################
  nixpkgs.config.allowUnfree = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  ########################################
  # Audio
  ########################################
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  ########################################
  # Desktop Services
  ########################################
  services.dbus.enable = true;
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  # Keep printing support from the fresh installer configuration.
  services.printing.enable = true;

  ########################################
  # Portals
  ########################################
  xdg.portal = {
    enable = true;
    # Plasma already supplies xdg-desktop-portal-kde itself.
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };

  ########################################
  # Fonts
  ########################################
  fonts.fontconfig.enable = true;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    noto-fonts-color-emoji
  ];

  ########################################
  # Packages
  ########################################
  environment.systemPackages = with pkgs; [
    # Shell / Terminal
    kitty

    # System / CLI tools
    curl
    git
    unzip
    openssl
    tree
    fastfetch
    btop
    wl-clipboard
    gparted
    gnome-disk-utility

    # Desktop / Editor
    kdePackages.kate

    # Video / Media
    kdePackages.kdenlive
    vlc
    ffmpeg-full
    sox
    ffmpegthumbnailer
    yt-dlp

    # Browser
    google-chrome

    # Graphics / Capture
    obs-studio
    gimp

    # Gaming
    lutris

    # AMD / Vulkan / VAAPI diagnostics
    libva-utils
    vulkan-tools
  ];

  ########################################
  # Firefox / Steam
  ########################################
  programs.firefox.enable = true;
  programs.steam.enable = true;

  ########################################
  # Game / Media Drives
  #
  # Keep disabled until the additional drives are physically installed.
  # After the next boot, verify labels and filesystems before uncommenting.
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

fileSystems."/mnt/Homelab" = {
  device = "/dev/disk/by-label/Homelab";
  fsType = "ext4";
  options = [ "noatime" "nofail" "x-systemd.device-timeout=1s" ];
};

  ########################################
  # State Version
  ########################################
  system.stateVersion = "26.05";
}
