# nixflakes

A collection of Nix flakes providing custom packages and overlays for easy reuse across projects.

## Available Packages

- **acli** - Anthropic CLI tool
- **claude-code** - Claude Code CLI tool

## Usage in Your Project

You can use these packages and overlays in your own Nix projects in several ways:

### Quick Start

1. **Copy the template**: Copy `template_flake.nix` from this repository to your project as `flake.nix`

2. **Run the development shell**:
   ```bash
   nix develop
   ```

   This will automatically:
   - Create a `.gitignore.nixflakes` file with recommended patterns
   - Add these patterns to your `.gitignore` (only if not already present)
   - Load the nixflakes packages into your environment

3. **Or run packages directly**:
   ```bash
   nix run github:3malkuth/nixflakes#claude-code
   nix run github:3malkuth/nixflakes#acli
   ```

### Method 1: Use Packages Directly

Add to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixflakes.url = "github:3malkuth/nixflakes";
  };

  outputs = { self, nixpkgs, nixflakes }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          nixflakes.packages.${system}.acli
          nixflakes.packages.${system}.claude-code
        ];
      };
    };
}
```

### Method 2: Use the Overlay

Add to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixflakes.url = "github:3malkuth/nixflakes";
  };

  outputs = { self, nixpkgs, nixflakes }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ nixflakes.overlays.default ];
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          pkgs.acli
          pkgs.claude-code
        ];
      };
    };
}
```

### Method 3: NixOS Configuration

In your `/etc/nixos/flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixflakes.url = "github:3malkuth/nixflakes";
  };

  outputs = { self, nixpkgs, nixflakes }: {
    nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        {
          nixpkgs.overlays = [ nixflakes.overlays.default ];
        }
      ];
    };
  };
}
```

Then in your `configuration.nix`:

```nix
{
  environment.systemPackages = with pkgs; [
    acli
    claude-code
  ];
}
```

### Method 4: Home Manager

In your `home.nix`:

```nix
{
  home.packages = [
    inputs.nixflakes.packages.${system}.acli
    inputs.nixflakes.packages.${system}.claude-code
  ];
}
```

Or with overlay:

```nix
{
  nixpkgs.overlays = [ inputs.nixflakes.overlays.default ];
  home.packages = with pkgs; [
    acli
    claude-code
  ];
}
```

## Gitignore Integration

When you use the template and run `nix develop`, it automatically:

1. Creates a `.gitignore.nixflakes` file with recommended patterns for Nix development
2. Appends these patterns to your main `.gitignore` file (if not already present)
3. Uses marker comments to prevent duplicate additions

The patterns include:
- Nix build outputs (`result`, `result-*`)
- direnv files (`.direnv`)
- Local development configurations
- Secrets and sensitive files
- Temporary directories

If you already have these patterns or don't want them, you can safely remove them from your `.gitignore` after the first run.

## Try Without Installing

You can try any package without installing:

```bash
# Run claude-code
nix run github:3malkuth/nixflakes#claude-code

# Run acli
nix run github:3malkuth/nixflakes#acli

# Open a shell with both packages
nix shell github:3malkuth/nixflakes#acli github:3malkuth/nixflakes#claude-code
```

## Development

### Local Development

If you're developing this repository locally:

```bash
nix develop
```

### NOTE!

- If you move the files from here to another folder you need to "git add" them first before "nix develop" will work!

- Delete the following file as it is automatically created ".config/starship.toml"
  - Don't create a script to automatically delete it as this will mess things up if you have several sessions open
    - and you constantly start and stop shells... shells will run without a config and default back to default settings

```bash
rm .config/starship.toml
```

## Adding New Packages

1. Create a new package directory in `nix/packages/your-package/`
2. Add the package definition in `default.nix`
3. Add the package to `nix/overlays/default.nix`
4. Expose it in the main `flake.nix` packages output

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

