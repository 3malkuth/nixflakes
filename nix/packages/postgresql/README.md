# PostgreSQL Local Package

PostgreSQL with local data and config directories for isolated development environments.

## Features

- Local data directory: `postgresql_data/`
- Local config directory: `postgresql_config/`
- Unix sockets in data directory (no system permissions needed)
- Automatic setup and initialization

## Usage

### Starting PostgreSQL

```bash
pg_ctl start
```

### Stopping PostgreSQL

```bash
pg_ctl stop
```

### Connecting to PostgreSQL

Connect to the default database as the postgres user:

```bash
psql -U postgres
```

Or connect to a specific database:

```bash
psql -U postgres -d postgres
```

### Creating Your Own User and Database

For easier access without specifying the username each time:

```bash
# Create a user with your username
createuser -U postgres $USER

# Create a database owned by your user
createdb -U postgres -O $USER $USER

# Now you can connect without specifying username
psql
```

## Configuration

The PostgreSQL configuration is automatically managed:

- Data directory: Uses `$PGDATA` or defaults to `postgresql_data/` in your project root
- Unix socket directory: Set to the data directory for local development
- Default settings: localhost only, port 5432, trust authentication

To customize settings, edit `postgresql_data/postgresql.conf` after initialization.

## Troubleshooting

If you encounter socket-related errors, run the setup script manually:

```bash
postgresql-setup
```

This will ensure the configuration is properly updated with the correct paths.
