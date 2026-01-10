{ pkgs }:

{
  # Environment variables
  env = [
    { name = "HOME"; eval = "$PRJ_ROOT"; }
    { name = "XDG_CONFIG_HOME"; eval = "$PRJ_ROOT/.config"; }
    { name = "XDG_DATA_HOME"; eval = "$PRJ_ROOT/.local/share"; }
    { name = "XDG_CACHE_HOME"; eval = "$PRJ_ROOT/.cache"; }
    { name = "SECRETS_DIR"; eval = "$PRJ_ROOT/.secrets"; }
    { name = "STARSHIP_CONFIG"; eval = "$PRJ_ROOT/.config/starship.toml"; }
  ];

  # Startup script
  startup = ''
    mkdir -p .config .local/share .cache .secrets

    # Ensure .secrets is gitignored
    if [ ! -f .gitignore ] || ! grep -q "^\.secrets" .gitignore 2>/dev/null; then
      echo -e "\n# Secrets - never commit\n.secrets/\n.envrc.local" >> .gitignore
    fi

    # Create .envrc.local template
    if [ ! -f .envrc.local ]; then
      cat > .envrc.local << 'EOF'
# Local secrets - this file is gitignored
# export GITHUB_TOKEN=xxx
# export CLAUDE_API_KEY=xxx
# export ATLASSIAN_TOKEN=xxx
EOF
    fi

    # Create starship config if it doesn't exist (using default config like the demo)
    if [ ! -f .config/starship.toml ]; then
      # Get the project directory name
      PROJECT_NAME=$(basename "$PRJ_ROOT")
      
      cat > .config/starship.toml << EOF
# Default starship config (matches starship.rs demo)
"\$schema" = 'https://starship.rs/config-schema.json'

add_newline = true

# Show directory at the start of the prompt
format = "\$directory\$all"

[directory]
home_symbol = "$PROJECT_NAME"

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
EOF
    fi

    # Source local secrets
    [ -f .envrc.local ] && source .envrc.local

    # Setup PostgreSQL environment
    if command -v postgresql-setup &> /dev/null; then
      # Run setup (creates dirs and initializes if needed)
      postgresql-setup

      # Set environment variables in current shell
      export PGDATA="$PRJ_ROOT/postgresql_data"
      export PGHOST="$PGDATA"
    fi

    # Initialize starship prompt
    eval "$(starship init bash)"

    alias v='nvim'
    alias l='ls -alh'
    alias s='git status'
  '';
}
