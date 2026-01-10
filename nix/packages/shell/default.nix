{ pkgs }:

# Returns a function that creates a customizable nixflakes shell
# Usage: mkNixflakesShell { extraPackages = [...]; extraStartup = "..."; }
{ extraPackages ? [], extraStartup ? "" }:

let
  # Common shell configuration
  shellConfig = import ../../config/shell.nix { inherit pkgs; };

  # Gitignore setup script (to be added to startup)
  gitignoreSetup = ''
    # Setup gitignore patterns from nixflakes
    GITIGNORE_NIXFLAKES=".gitignore.nixflakes"
    GITIGNORE_MAIN=".gitignore"

    # Create the nixflakes gitignore file with recommended patterns
    cat > "$GITIGNORE_NIXFLAKES" << 'EOF'

# the nixflakes generated .gitignore file
.gitignore.nixflakes

# Ignore build outputs from performing a nix-build or nix build command
result
result-*

# Ignore automatically generated direnv output
.direnv

# Local configurations
postgresql_data/
postgresql_config/
debug.log

.python_history
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
  '';

  # Base packages (from nix/packages/default.nix)
  basePackages = import ../default.nix { inherit pkgs; };
in
pkgs.devshell.mkShell {
  name = "nixflakes-shell";

  # Use the combined package set plus any extra packages
  packages = basePackages.all ++ extraPackages;

  # Environment variables
  env = shellConfig.env;

  # Startup script with gitignore setup and any extra startup commands
  devshell.startup.init.text = gitignoreSetup + "\n" + shellConfig.startup + "\n" + extraStartup;
}
