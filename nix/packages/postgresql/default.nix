{ lib
, postgresql_17
, writeShellScriptBin
, makeWrapper
, symlinkJoin
}:

let
  # Get the repo root directory (4 levels up from this file)
  repoRoot = builtins.toString ../../../..;

  # PostgreSQL wrapper that sets up local data and config directories
  postgresqlWrapper = writeShellScriptBin "postgres" ''
    export PGDATA="${repoRoot}/postgresql_data"
    export PGHOST="$PGDATA"

    # Ensure directories exist
    mkdir -p "$PGDATA"
    mkdir -p "${repoRoot}/postgresql_config"

    # Initialize database if it doesn't exist
    if [ ! -f "$PGDATA/PG_VERSION" ]; then
      echo "Initializing PostgreSQL database in $PGDATA..."
      ${postgresql_17}/bin/initdb -D "$PGDATA" \
        --encoding=UTF8 \
        --locale=C \
        --auth=trust \
        --username=postgres

      # Create a custom postgresql.conf in the config directory
      cat > "${repoRoot}/postgresql_config/postgresql.conf" <<EOF
# Custom PostgreSQL configuration
# Data directory: $PGDATA
# Unix socket directory: $PGDATA
unix_socket_directories = '$PGDATA'
listen_addresses = 'localhost'
port = 5432
max_connections = 100
shared_buffers = 128MB
EOF

      # Copy the config to data directory
      cp "${repoRoot}/postgresql_config/postgresql.conf" "$PGDATA/postgresql.conf"
    fi

    # Run postgres with the configured data directory
    exec ${postgresql_17}/bin/postgres "$@"
  '';

  # Wrapper for pg_ctl
  pgCtlWrapper = writeShellScriptBin "pg_ctl" ''
    export PGDATA="${repoRoot}/postgresql_data"
    export PGHOST="$PGDATA"
    exec ${postgresql_17}/bin/pg_ctl "$@"
  '';

  # Wrapper for psql
  psqlWrapper = writeShellScriptBin "psql" ''
    export PGDATA="${repoRoot}/postgresql_data"
    export PGHOST="$PGDATA"
    exec ${postgresql_17}/bin/psql "$@"
  '';

  # Wrapper for createdb
  createdbWrapper = writeShellScriptBin "createdb" ''
    export PGDATA="${repoRoot}/postgresql_data"
    export PGHOST="$PGDATA"
    exec ${postgresql_17}/bin/createdb "$@"
  '';

  # Wrapper for dropdb
  dropdbWrapper = writeShellScriptBin "dropdb" ''
    export PGDATA="${repoRoot}/postgresql_data"
    export PGHOST="$PGDATA"
    exec ${postgresql_17}/bin/dropdb "$@"
  '';

in
symlinkJoin {
  name = "postgresql-local";
  paths = [
    postgresql_17
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
