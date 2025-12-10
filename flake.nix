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
        }
      );

      # Expose overlays for reuse in other flakes
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

          # Import package sets (uses pkgs with overlays applied)
          packages = import ./nix/packages { inherit pkgs; };

          # Import shell configuration
          shellConfig = import ./nix/config/shell.nix { inherit pkgs; };

        in
        {
          default = pkgs.devshell.mkShell {
            name = "nix-shell";

            # Use the combined package set
            packages = packages.all;

            env = shellConfig.env;

            devshell.startup.init.text = shellConfig.startup;
          };
        }
      );
    };
}
