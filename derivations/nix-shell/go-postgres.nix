with import <nixpkgs> { };
mkShell
{
  buildInputs = [
    postgresql
    go
  ];
}

# Create a database with the data stored in the current directory (if db already this should be skipped)
# initdb -D {db_path}

# Start PostgreSQL running as the current user
# and with the Unix socket in the current directory
# pg_ctl - D {db_path} - l logfile - o "--unix_socket_directories='$PWD'" start

# Create database
# createdb - h "$PWD" { db_name }

# Stop PostgreSQL
# pg_ctl -D {db_path} stop



