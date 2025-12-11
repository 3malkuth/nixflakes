{
  description = "Template for using nixflakes packages and overlays";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Add the nixflakes repository
    nixflakes.url = "github:3malkuth/nixflakes";

    # Optional: Pin to a specific branch, tag, or commit
    # nixflakes.url = "github:3malkuth/nixflakes/main";
    # nixflakes.url = "github:3malkuth/nixflakes/v1.0.0";
    # nixflakes.url = "github:3malkuth/nixflakes/abc123def456";
  };

  outputs = { self, nixpkgs, nixflakes }:
    let
      system = "x86_64-linux"; # Change to your system: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin

      # Option 1: Use packages directly without overlay
      pkgs-plain = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      # Option 2: Use nixpkgs with the overlay applied
      pkgs-with-overlay = import nixpkgs {
        inherit system;
        overlays = [ nixflakes.overlays.default ];
        config.allowUnfree = true;
      };
    in
    {
      # Example 1: Create a development shell with the packages
      devShells.${system}.default = pkgs-plain.mkShell {
        buildInputs = [
          # Access packages directly from the flake
          nixflakes.packages.${system}.acli
          nixflakes.packages.${system}.claude-code

          # Add other dependencies
          pkgs-plain.git
        ];

        shellHook = ''
          # Setup gitignore patterns from nixflakes
          GITIGNORE_NIXFLAKES=".gitignore.nixflakes"
          GITIGNORE_MAIN=".gitignore"

          # Create the nixflakes gitignore file with recommended patterns
          cat > "$GITIGNORE_NIXFLAKES" << 'EOF'
# Ignore build outputs from performing a nix-build or nix build command
result
result-*

# Ignore automatically generated direnv output
.direnv

# Local configurations
.claude/
.cache/
.config/
.local/
.npm/
.viminfo
.claude.json
.claude.json.backup
.bash_history
.w3m/
debug.log

# Secrets - never commit
.secrets/
.gnupg/
.envrc.local

# Temp Folder for test scripts etc.
/tmp
EOF

          # Check if main .gitignore exists, create if it doesn't
          if [ ! -f "$GITIGNORE_MAIN" ]; then
            touch "$GITIGNORE_MAIN"
          fi

          # Check if the nixflakes patterns are already included
          if ! grep -q "# BEGIN nixflakes gitignore patterns" "$GITIGNORE_MAIN"; then
            echo "" >> "$GITIGNORE_MAIN"
            echo "# BEGIN nixflakes gitignore patterns (auto-generated)" >> "$GITIGNORE_MAIN"
            cat "$GITIGNORE_NIXFLAKES" >> "$GITIGNORE_MAIN"
            echo "# END nixflakes gitignore patterns" >> "$GITIGNORE_MAIN"
            echo "✓ Added nixflakes gitignore patterns to $GITIGNORE_MAIN"
          fi

          echo "Development environment loaded!"
          echo "Available packages: acli, claude-code"
        '';
      };

      # Example 2: Create a shell using the overlay
      devShells.${system}.with-overlay = pkgs-with-overlay.mkShell {
        buildInputs = [
          # Access packages through the overlay
          pkgs-with-overlay.acli
          pkgs-with-overlay.claude-code

          # Other packages
          pkgs-with-overlay.git
        ];

        shellHook = ''
          # Setup gitignore patterns from nixflakes
          GITIGNORE_NIXFLAKES=".gitignore.nixflakes"
          GITIGNORE_MAIN=".gitignore"

          # Create the nixflakes gitignore file with recommended patterns
          cat > "$GITIGNORE_NIXFLAKES" << 'EOF'
# Ignore build outputs from performing a nix-build or nix build command
result
result-*

# Ignore automatically generated direnv output
.direnv

# Local configurations
.claude/
.cache/
.config/
.local/
.npm/
.viminfo
.claude.json
.claude.json.backup
.bash_history
.w3m/
debug.log

# Secrets - never commit
.secrets/
.gnupg/
.envrc.local

# Temp Folder for test scripts etc.
/tmp
EOF

          # Check if main .gitignore exists, create if it doesn't
          if [ ! -f "$GITIGNORE_MAIN" ]; then
            touch "$GITIGNORE_MAIN"
          fi

          # Check if the nixflakes patterns are already included
          if ! grep -q "# BEGIN nixflakes gitignore patterns" "$GITIGNORE_MAIN"; then
            echo "" >> "$GITIGNORE_MAIN"
            echo "# BEGIN nixflakes gitignore patterns (auto-generated)" >> "$GITIGNORE_MAIN"
            cat "$GITIGNORE_NIXFLAKES" >> "$GITIGNORE_MAIN"
            echo "# END nixflakes gitignore patterns" >> "$GITIGNORE_MAIN"
            echo "✓ Added nixflakes gitignore patterns to $GITIGNORE_MAIN"
          fi

          echo "Development environment loaded!"
          echo "Available packages: acli, claude-code"
        '';
      };

      # Example 3: Expose specific packages for `nix run`
      packages.${system} = {
        # Re-export packages
        acli = nixflakes.packages.${system}.acli;
        claude-code = nixflakes.packages.${system}.claude-code;

        # Set a default package
        default = nixflakes.packages.${system}.claude-code;
      };

      # Example 4: Use in NixOS configuration
      # In your NixOS configuration.nix, you can:
      # 1. Add the overlay to nixpkgs.overlays
      # 2. Then use the packages in environment.systemPackages
      #
      # nixpkgs.overlays = [ nixflakes.overlays.default ];
      # environment.systemPackages = with pkgs; [
      #   acli
      #   claude-code
      # ];

      # Example 5: Use in home-manager
      # In your home.nix:
      # home.packages = [
      #   nixflakes.packages.${system}.acli
      #   nixflakes.packages.${system}.claude-code
      # ];
      #
      # Or with overlay:
      # nixpkgs.overlays = [ nixflakes.overlays.default ];
      # home.packages = with pkgs; [
      #   acli
      #   claude-code
      # ];
    };
}
