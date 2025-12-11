# Custom overlays for the project
# This file composes all custom overlays together

final: prev: {
  # Custom packages overlay
  acli = final.callPackage ../packages/acli { };
  claude-code = final.callPackage ../packages/claude { };
}
