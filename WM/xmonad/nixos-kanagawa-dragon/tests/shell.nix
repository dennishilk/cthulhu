{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
  packages = [
    pkgs.python3 pkgs.shellcheck
    (pkgs.haskellPackages.ghcWithPackages (p: [ p.xmonad p.xmonad-contrib p.xmobar ]))
  ];
}
