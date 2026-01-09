{
  description = "Development environment with isolated home directory";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, devshell }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      # Expose custom packages as flake outputs
      packages = forAllSystems (system:
        let
          customOverlays = import ./nix/overlays;
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ customOverlays ];
            config.allowUnfree = true;
          };
        in
        {
          acli = pkgs.acli;
          claude-code = pkgs.claude-code;
          python3Custom = pkgs.python3Custom;
          postgresqlLocal = pkgs.postgresqlLocal;
        }
      );

      # Expose overlays for reuse in other flakes
      # The overlay includes:
      # - acli: Anthropic CLI
      # - claude-code: Claude Code CLI
      # - python3Custom: Python3 with customizable packages
      # - postgresqlLocal: PostgreSQL with local data/config directories
      # - mkNixflakesShell: Function to create pre-configured devshell
      overlays.default = import ./nix/overlays;

      devShells = forAllSystems (system:
        let
          # Import custom overlays
          customOverlays = import ./nix/overlays;

          # Create pkgs with all overlays applied
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              devshell.overlays.default
              customOverlays
            ];
            config.allowUnfree = true;
          };

        in
        {
          # Use the mkNixflakesShell function from our overlay
          default = pkgs.mkNixflakesShell { };
        }
      );
    };
}
