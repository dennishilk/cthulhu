# Evaluation fixtures only: fake disk/account, never install this file on a host.
let
  evaluate = { plasma, standalone, extras ? false }:
    let
      system = import <nixpkgs/nixos> {
        configuration = { ... }: {
          imports = [ ../nixos/desktop.nix ];
          nixpkgs.hostPlatform = "x86_64-linux";
          cthulhu.desktop = {
            enable = true;
            user = "reader";
            inherit standalone;
            personalApps = extras;
            gaming = extras;
          };
          users.users.reader.isNormalUser = true;
          services.desktopManager.plasma6.enable = plasma;
          services.displayManager.sddm.enable = plasma;
          fileSystems."/" = { device = "/dev/test-only"; fsType = "ext4"; };
          boot.loader.grub.enable = false;
          system.stateVersion = "26.05";
        };
      };
      c = system.config;
      failures = builtins.filter (a: !a.assertion) c.assertions;
    in
      assert failures == [ ];
      assert c.services.xserver.displayManager.startx.generateScript;
      assert c.services.desktopManager.plasma6.enable == (plasma && !standalone);
      assert c.services.displayManager.sddm.enable == (plasma && !standalone);
      assert c.system.stateVersion == "26.05";
      builtins.deepSeq c.system.build.toplevel.drvPath true;
in {
  plasmaPreparation = evaluate { plasma = true; standalone = false; };
  plasmaToStandalone = evaluate { plasma = true; standalone = true; };
  minimal = evaluate { plasma = false; standalone = true; };
  optionalApplications = evaluate { plasma = false; standalone = true; extras = true; };
}
