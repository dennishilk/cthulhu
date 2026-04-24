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

  system.build.label = "Cthulhu – Radeon";
  systemd.defaultUnit = "graphical.target";

  ########################################
  # Nix & GC
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
  # Kernel
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
    "vm.vfs_cache_pressure" = 150;
    "vm.dirty_ratio" = 15;
    "vm.dirty_background_ratio" = 5;
  };

  ########################################
  # Virtualisation
  ########################################
  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.qemu.swtpm.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;

  services.spice-vdagentd.enable = true;
  programs.virt-manager.enable = true;

  ########################################
  # User
  ########################################
  users.users.nebu = {
    isNormalUser = true;
    shell = pkgs.zsh;
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
  # ZSH + Powerlevel10k
  ########################################
  programs.zsh = {
    enable = true;

    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    promptInit = ''
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
    '';

    shellAliases = {
      ll = "ls -lah";
    };
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
  console.keyMap = "de";

  ########################################
  # Display, KDE Plasma, river
  ########################################
  services.xserver.enable = true;
  services.xserver.xkb.layout = "de";

  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.displayManager.defaultSession = "plasma";

  services.desktopManager.plasma6.enable = true;

  programs.river-classic.enable = true;

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
  services.tumbler.enable = true;

  ########################################
  # Flatpak & Portals
  ########################################
  services.flatpak.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      kdePackages.xdg-desktop-portal-kde
      xdg-desktop-portal-gtk
    ];
    config.common.default = "*";
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
    zsh-powerlevel10k
    alacritty

    # System tools
    curl
    git
    unzip
    openssl
    tree
    fastfetch
    btop
    gparted
    gnome-disk-utility

    # Desktop / Files
    xfce.mousepad

    # KDE / Video / Media
    kdePackages.kdenlive
    vlc
    ffmpeg-full
    sox
    ffmpegthumbnailer
    yt-dlp

    # Browser / Internet
    firefox
    google-chrome

    # Audio control
    pamixer
    pavucontrol

    # Wayland / river
    waybar
    rofi
    wl-clipboard
    grim
    slurp

    # Graphics / Capture
    obs-studio
    gimp

    # Gaming
    steam
    wowup-cf
    gamemode
    mangohud

    # AMD / Vulkan / VAAPI tools
    libva-utils
    vulkan-tools
  ];

  ########################################
  # Steam
  ########################################
  programs.steam.enable = true;

  ########################################
  # Game / Media Drives
  # Disabled for now.
  # Format and label the drives with GParted first:
  #   Games.Vol1
  #   Games.Vol2
  #   homelab
  ########################################

  # fileSystems."/mnt/Games.Vol1" = {
  #   device = "/dev/disk/by-label/Games.Vol1";
  #   fsType = "ext4";
  #   options = [ "noatime" "nofail" "x-systemd.device-timeout=1s" ];
  # };

  # fileSystems."/mnt/Games.Vol2" = {
  #   device = "/dev/disk/by-label/Games.Vol2";
  #   fsType = "ext4";
  #   options = [ "noatime" "nofail" "x-systemd.device-timeout=1s" ];
  # };

  # fileSystems."/mnt/Homelab" = {
  #   device = "/dev/disk/by-label/homelab";
  #   fsType = "ext4";
  #   options = [ "noatime" "nofail" "x-systemd.device-timeout=1s" ];
  # };

  ########################################
  # State Version
  ########################################
  system.stateVersion = "25.05";
}
