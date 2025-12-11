{ pkgs }:

let
  # Base development tools
  # These are standard nixpkgs packages
  base = with pkgs; [
    neovim
    wget
    w3m
    browsh
    coreutils
    gnugrep
    less
    neomutt
    nodejs_20
    starship
  ];

  # Custom packages (provided via overlays)
  # These are defined in nix/overlays/default.nix
  custom = with pkgs; [
    acli
    claude-code
  ];
in
{
  inherit base custom;

  # All packages combined
  all = base ++ custom;
}
