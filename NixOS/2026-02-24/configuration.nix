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
  system.build.label = "Cthulhu – Stable";

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
  # nix-ld (für externe Binaries wie Unigine)
  ########################################
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [

      # Core runtime
      stdenv.cc.cc
      zlib
      glib

      # OpenGL / Vulkan
      libGL
      vulkan-loader

      # X11 Core
      xorg.libX11
      xorg.libXrandr
      xorg.libXcursor
      xorg.libXi
      xorg.libXext
      xorg.libXinerama
      xorg.libXrender
      xorg.libXfixes
      xorg.libXxf86vm

      # XCB stack
      xorg.libxcb
      xorg.xcbutil
      xorg.xcbutilimage
      xorg.xcbutilkeysyms
      xorg.xcbutilrenderutil
      xorg.xcbutilwm
    ];
  };

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
  virtualisation.libvirtd.qemu.ovmf.enable = true;
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
  # X11 + Plasma
  ########################################
  services.xserver.enable = true;
  services.xserver.xkb.layout = "de";
  services.xserver.videoDrivers = [ "nvidia" ];

  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = false;
  services.displayManager.defaultSession = "plasmax11";
  services.desktopManager.plasma6.enable = true;

  ########################################
  # NVIDIA
  ########################################
  nixpkgs.config.allowUnfree = true;

  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  hardware.nvidia = {
    open = false;
    modesetting.enable = true;
    powerManagement.enable = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  ########################################
  # Audio
  ########################################
  services.pipewire.enable = true;
  services.pipewire.alsa.enable = true;
  services.pipewire.alsa.support32Bit = true;
  services.pipewire.pulse.enable = true;
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
  # Flatpak
  ########################################
  services.flatpak.enable = true;

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  xdg.portal.config.common.default = "*";

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
  # Packages
  ########################################
  environment.systemPackages = with pkgs; [
    zsh-powerlevel10k
    curl wget git unzip openssl tree tmux fastfetch btop iotop gparted
    zoom-us ffmpeg-full sox imagemagick ffmpegthumbnailer poppler_utils yt-dlp
    pamixer pavucontrol xbindkeys
    wmctrl xorg.xrandr xorg.xev xterm
    kitty typora xfce.mousepad file-roller eog dconf
    gnome-disk-utility firefox google-chrome blender
    kdePackages.kdenlive vlc gimp wireshark

    (pkgs.obs-studio.override {
      cudaSupport = true;
      ffmpeg = pkgs.ffmpeg-full;
    })

    steam wowup-cf gamemode mangohud
    libva-utils nvidia-vaapi-driver vulkan-tools
    python311 python311Packages.pip
    tor-browser-bundle-bin
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