{ lib
, postgresql_17
, writeShellScriptBin
, writeTextFile
, makeWrapper
, symlinkJoin
}:

let
  # Get the repo root directory (4 levels up from this file)
  repoRoot = builtins.toString ../../../..;

  # Setup script that runs on shell initialization
  setupScript = writeShellScriptBin "postgresql-setup" ''
    # Function to set PostgreSQL environment variables
    setup_postgresql_env() {
      if [ -z "$PGDATA" ]; then
        export PGDATA="${repoRoot}/postgresql_data"
      fi

      if [ -z "$PGHOST" ]; then
        export PGHOST="$PGDATA"
      fi
    }

    # Function to create directories if they don't exist
    setup_postgresql_dirs() {
      if [ ! -d "${repoRoot}/postgresql_data" ]; then
        mkdir -p "${repoRoot}/postgresql_data"
        echo "✓ Created postgresql_data directory"
      fi

      if [ ! -d "${repoRoot}/postgresql_config" ]; then
        mkdir -p "${repoRoot}/postgresql_config"
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
      local config_file="${repoRoot}/postgresql_config/postgresql.conf"

      if [ ! -f "$config_file" ]; then
        cat > "$config_file" <<EOF
# Custom PostgreSQL configuration
# Data directory: $PGDATA
# Unix socket directory: $PGDATA
unix_socket_directories = '$PGDATA'
listen_addresses = 'localhost'
port = 5432
max_connections = 100
shared_buffers = 128MB
EOF
        echo "✓ Created postgresql.conf in postgresql_config/"
      fi

      # Copy config to data directory if not already there
      if [ -f "$config_file" ] && [ ! -f "$PGDATA/postgresql.conf" ]; then
        cp "$config_file" "$PGDATA/postgresql.conf"
        echo "✓ Copied postgresql.conf to data directory"
      fi
    }

    # Run setup functions in order
    setup_postgresql_env
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
