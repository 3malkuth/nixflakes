# Custom overlays for the project
# This file composes all custom overlays together

final: prev: {
  # Custom packages overlay
  acli = final.callPackage ../packages/acli { };
  claude-code = final.callPackage ../packages/claude { };

  # Shell configuration function
  # Usage: pkgs.mkNixflakesShell { extraPackages = [...]; extraStartup = "..."; }
  mkNixflakesShell = final.callPackage ../packages/shell { };
}
