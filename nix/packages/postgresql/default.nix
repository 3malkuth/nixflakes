{ lib
, postgresql_17
, writeShellScriptBin
, writeTextFile
, makeWrapper
, symlinkJoin
}:

let
  # Setup script that runs on shell initialization
  setupScript = writeShellScriptBin "postgresql-setup" ''
    # Use PRJ_ROOT if available (from devshell), otherwise use PWD
    REPO_ROOT="''${PRJ_ROOT:-$PWD}"
    DATA_DIR="$REPO_ROOT/postgresql_data"
    CONFIG_DIR="$REPO_ROOT/postgresql_config"

    # Use provided PGDATA or default to repo data dir
    PGDATA="''${PGDATA:-$DATA_DIR}"

    # Function to create directories if they don't exist
    setup_postgresql_dirs() {
      if [ ! -d "$DATA_DIR" ]; then
        mkdir -p "$DATA_DIR"
        echo "✓ Created postgresql_data directory"
      fi

      if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
        echo "✓ Created postgresql_config directory"
      fi
    }

    # Function to initialize PostgreSQL database
    setup_postgresql_init() {
      if [ ! -f "$PGDATA/PG_VERSION" ]; then
        echo "Initializing PostgreSQL database in $PGDATA..."
        ${postgresql_17}/bin/initdb -D "$PGDATA" \
          --encoding=UTF8 \
          --locale=C \
          --auth=trust \
          --username=postgres
        echo "✓ PostgreSQL database initialized"
      fi
    }

    # Function to create config file
    setup_postgresql_config() {
      local config_file="$CONFIG_DIR/postgresql.conf"
      local pgdata_config="$PGDATA/postgresql.conf"

      # Create custom config template in CONFIG_DIR if it doesn't exist
      if [ ! -f "$config_file" ]; then
        cat > "$config_file" <<EOF
# Custom PostgreSQL configuration
# Data directory: dynamically set to \$PGDATA
# Unix socket directory: dynamically set to \$PGDATA
listen_addresses = 'localhost'
port = 5432
max_connections = 100
shared_buffers = 128MB
EOF
        echo "✓ Created postgresql.conf template in postgresql_config/"
      fi

      # Update or create the postgresql.conf in PGDATA
      if [ -f "$pgdata_config" ]; then
        # Update existing config to use current PGDATA for socket directory
        if grep -q "^#*unix_socket_directories" "$pgdata_config"; then
          # Replace existing line (commented or uncommented) with actual PGDATA path
          sed -i "s|^#*unix_socket_directories.*|unix_socket_directories = '$PGDATA'|" "$pgdata_config"
          echo "✓ Updated unix_socket_directories to $PGDATA"
        else
          # Add if not present
          echo "unix_socket_directories = '$PGDATA'" >> "$pgdata_config"
          echo "✓ Added unix_socket_directories = $PGDATA"
        fi
      else
        # Create new config with PGDATA
        cat > "$pgdata_config" <<EOF
# PostgreSQL configuration
# Unix socket directory set to data directory for local development
unix_socket_directories = '$PGDATA'
listen_addresses = 'localhost'
port = 5432
max_connections = 100
shared_buffers = 128MB
EOF
        echo "✓ Created postgresql.conf in data directory"
      fi
    }

    # Run setup functions in order
    setup_postgresql_dirs
    setup_postgresql_init
    setup_postgresql_config
  '';

  # PostgreSQL wrapper that sets up local data and config directories
  postgresqlWrapper = writeShellScriptBin "postgres" ''
    # Run setup if not already done
    if [ -z "$PGDATA" ]; then
      postgresql-setup
    fi

    # Run postgres with the configured data directory
    exec ${postgresql_17}/bin/postgres "$@"
  '';

  # Wrapper for pg_ctl
  pgCtlWrapper = writeShellScriptBin "pg_ctl" ''
    # Run setup if not already done
    if [ -z "$PGDATA" ]; then
      postgresql-setup
    fi
    exec ${postgresql_17}/bin/pg_ctl "$@"
  '';

  # Wrapper for psql
  psqlWrapper = writeShellScriptBin "psql" ''
    # Run setup if not already done
    if [ -z "$PGDATA" ]; then
      postgresql-setup
    fi
    exec ${postgresql_17}/bin/psql "$@"
  '';

  # Wrapper for createdb
  createdbWrapper = writeShellScriptBin "createdb" ''
    # Run setup if not already done
    if [ -z "$PGDATA" ]; then
      postgresql-setup
    fi
    exec ${postgresql_17}/bin/createdb "$@"
  '';

  # Wrapper for dropdb
  dropdbWrapper = writeShellScriptBin "dropdb" ''
    # Run setup if not already done
    if [ -z "$PGDATA" ]; then
      postgresql-setup
    fi
    exec ${postgresql_17}/bin/dropdb "$@"
  '';

in
symlinkJoin {
  name = "postgresql-local";
  paths = [
    postgresql_17
    setupScript
    postgresqlWrapper
    pgCtlWrapper
    psqlWrapper
    createdbWrapper
    dropdbWrapper
  ];

  meta = with lib; {
    description = "PostgreSQL with local data and config directories";
    homepage = "https://www.postgresql.org";
    license = licenses.postgresql;
    platforms = platforms.unix;
    maintainers = [ ];
  };
}
