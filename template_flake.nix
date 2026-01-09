{
  description = "Template for using nixflakes packages and overlays";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Add the nixflakes repository
    nixflakes.url = "github:3malkuth/nixflakes";

    # devshell is required for the nixflakes shell
    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";

    # Optional: Pin to a specific branch, tag, or commit
    # nixflakes.url = "github:3malkuth/nixflakes/main";
    # nixflakes.url = "github:3malkuth/nixflakes/v1.0.0";
    # nixflakes.url = "github:3malkuth/nixflakes/abc123def456";
  };

  outputs = { self, nixpkgs, nixflakes, devshell }:
    let
      system = "x86_64-linux"; # Change to your system: x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin

      # Create pkgs with nixflakes overlay and devshell
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          devshell.overlays.default
          nixflakes.overlays.default
        ];
        config.allowUnfree = true;
      };
    in
    {
      # Development shells
      devShells.${system} = {
        # Use the pre-configured nixflakes shell
        # This includes starship, gitignore setup, secrets management, etc.
        default = pkgs.mkNixflakesShell {
          extraStartup = ''
	    # Ensure Nix-provided Python takes precedence over system Python
            export PATH="${pkgs.python3Custom}/bin:$PATH"
            echo "Using Nix-managed packages: acli, claude-code, python3Custom, postgresqlLocal"
            echo "Python: $(which python3)"
            echo "PostgreSQL data: postgresql_data/"
          '';
        };

        # Example: Minimal shell with just the packages (no nixflakes shell config)
        minimal = pkgs.mkShell {
          buildInputs = [
            pkgs.acli
            pkgs.claude-code
            pkgs.python3Custom
            pkgs.postgresqlLocal
          ];
        };

        # Example: Python3 shell with additional packages
        # To add Python packages, override python3Custom with your desired packages
        python = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Default python3Custom includes pip, setuptools, wheel
            # To add more packages:
            (python3.withPackages (ps: with ps; [
              pip
              setuptools
              wheel
              requests
              numpy
              pandas
            ]))
          ];
        };
      };

      # Optional: Expose packages for `nix run`
      packages.${system} = {
        # Access packages via overlay
        acli = pkgs.acli;
        claude-code = pkgs.claude-code;
        python3Custom = pkgs.python3Custom;
        postgresqlLocal = pkgs.postgresqlLocal;

        # Example: Custom Python with specific packages
        python3WithPackages = pkgs.python3.withPackages (ps: with ps; [
          pip
          setuptools
          wheel
          requests
          numpy
          pandas
        ]);

        default = pkgs.claude-code;
      };

      # For NixOS configuration:
      # In /etc/nixos/configuration.nix, add to imports:
      # nixpkgs.overlays = [ inputs.nixflakes.overlays.default ];
      # environment.systemPackages = with pkgs; [
      #   acli
      #   claude-code
      #   python3Custom
      #   postgresqlLocal
      #   # Or with custom packages:
      #   (python3.withPackages (ps: with ps; [ requests numpy pandas ]))
      # ];

      # For home-manager:
      # In home.nix:
      # nixpkgs.overlays = [ inputs.nixflakes.overlays.default ];
      # home.packages = with pkgs; [
      #   acli
      #   claude-code
      #   python3Custom
      #   postgresqlLocal
      #   # Or with custom packages:
      #   (python3.withPackages (ps: with ps; [ requests numpy pandas ]))
      # ];
    };
}
