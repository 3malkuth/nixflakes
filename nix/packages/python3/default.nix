{ python3
, lib
}:

# This creates a custom Python3 environment with specified packages
# Usage in overlay: python3Custom = final.callPackage ../packages/python3 { pythonPackages = [ ... ]; };

{ pythonPackages ? [] }:

python3.withPackages (ps: with ps; [
  # Core packages that are always included
  pip
  setuptools
  wheel

  # User-specified packages from pythonPackages parameter
] ++ pythonPackages)
