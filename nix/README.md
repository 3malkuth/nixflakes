# Nix Configuration Structure

This directory contains modular Nix configuration following best practices.

## Directory Structure

```
nix/
├── overlays/          # Custom package overlays
│   └── default.nix    # Main overlay composition
├── packages/          # Package definitions
│   ├── default.nix    # Package set definitions
│   └── acli/         # Individual package directories
│       └── default.nix
└── config/           # Configuration modules
    └── shell.nix     # Shell environment config
```

## Best Practices Used

### 1. Overlays
Custom packages are defined as overlays in `overlays/default.nix`. This allows:
- Packages to be easily shared with other flakes
- Proper composition with nixpkgs
- Reusable package definitions

### 2. CallPackage Pattern
Packages use `callPackage` for dependency injection:
- Dependencies declared as function arguments
- Automatic dependency resolution by Nix
- Better testability and reusability

Example in `packages/acli/default.nix`:
```nix
{ stdenv, fetchurl, lib }:  # Dependencies as arguments
stdenv.mkDerivation { ... }
```

### 3. Separation of Concerns
- **overlays/**: Package definitions and extensions to nixpkgs
- **packages/**: Package sets and lists
- **config/**: Environment and shell configurations

### 4. Flake Outputs
The main flake exposes multiple outputs:
- `packages.<system>.acli` - Build custom packages directly
- `overlays.default` - Reuse overlays in other flakes
- `devShells.<system>.default` - Development environment

## Adding New Packages

### For custom packages:

1. Create package directory:
   ```bash
   mkdir -p nix/packages/mypackage
   ```

2. Create `nix/packages/mypackage/default.nix`:
   ```nix
   { stdenv, fetchurl, lib }:

   stdenv.mkDerivation {
     pname = "mypackage";
     version = "1.0.0";
     # ... rest of package definition
   }
   ```

3. Add to overlay in `nix/overlays/default.nix`:
   ```nix
   final: prev: {
     acli = final.callPackage ../packages/acli { };
     mypackage = final.callPackage ../packages/mypackage { };
   }
   ```

4. Add to package set in `nix/packages/default.nix`:
   ```nix
   custom = with pkgs; [
     acli
     mypackage
   ];
   ```

5. Expose in flake outputs if needed (in `flake.nix`):
   ```nix
   packages = forAllSystems (system: {
     acli = pkgs.acli;
     mypackage = pkgs.mypackage;
   });
   ```

### For nixpkgs packages:

Simply add to the `base` list in `nix/packages/default.nix`:
```nix
base = with pkgs; [
  neovim
  # ... existing packages
  git  # new package
];
```

## Usage

```bash
# Enter development shell
nix develop

# Build a specific package
nix build .#acli

# Use overlay in another flake
{
  inputs.myproject.url = "path:/path/to/this/flake";

  overlays = [ myproject.overlays.default ];
}
```

## Benefits

- **Modular**: Easy to add/remove/modify packages
- **Composable**: Overlays can be reused in other flakes
- **Maintainable**: Clear separation of concerns
- **Discoverable**: Standard Nix patterns make it easy to understand
- **Flexible**: Can build packages individually or use the full dev shell
