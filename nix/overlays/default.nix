# Custom overlays for the project
# This file composes all custom overlays together

final: prev: {
  # Custom packages overlay
  acli = final.callPackage ../packages/acli { };
  claude-code = final.callPackage ../packages/claude { };

  # Python3 with customizable packages
  # Usage: python3Custom = pkgs.callPackage ../packages/python3 { pythonPackages = [ pkgs.python3Packages.requests ]; };
  # Default: python3Custom = pkgs.python3Custom; (includes only pip, setuptools, wheel)
  python3Custom = final.callPackage ../packages/python3 { };

  # Shell configuration function
  # Usage: pkgs.mkNixflakesShell { extraPackages = [...]; extraStartup = "..."; }
  mkNixflakesShell = final.callPackage ../packages/shell { };
}
