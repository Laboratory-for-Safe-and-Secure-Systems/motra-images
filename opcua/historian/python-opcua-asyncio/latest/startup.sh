#!/bin/sh

# treat undefined variables as an error
set -u

# if SERVER_URI is set, then use it instead
server_uri_opt=""
if [ -n "$SERVER_URI" ]; then
    server_uri_opt="--suri="
fi

# create the database if it does not exist yet AND create
# a lock file to indicate to other containers that the
# database is ready to use
DB_NAME="${DB_NAME:-/database/historian_database.sqlite3}"
LOCKFILE="${DB_NAME:-/database/historian_database.sqlite3}.lock"
if [ ! -f "$LOCKFILE" ]; then

    # define the SQL commands for creating the tables
    CREATE_TANK_WATER_LEVEL_TABLE="
    CREATE TABLE IF NOT EXISTS tank_water_level (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        pct REAL NOT NULL
    );
    "

    CREATE_CHEMICAL_VALVE_POS_TABLE="
    CREATE TABLE IF NOT EXISTS chemical_valve_pos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        position INTEGER NOT NULL
    );
    "

    CREATE_UPPER_LIMIT_TABLE="
    CREATE TABLE IF NOT EXISTS upper_limit (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        pct INTEGER NOT NULL
    );
    "

    CREATE_LOWER_LIMIT_TABLE="
    CREATE TABLE IF NOT EXISTS lower_limit (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
        pct INTEGER NOT NULL
    );
    "

    sqlite3 "$DB_NAME" <<EOF
    $CREATE_TANK_WATER_LEVEL_TABLE
    $CREATE_CHEMICAL_VALVE_POS_TABLE
    $CREATE_UPPER_LIMIT_TABLE
    $CREATE_LOWER_LIMIT_TABLE
    EOF

    # create the file to indicate to other containers that
    # the database is ready to use
    touch "$LOCKFILE"
fi

# if no ENV is set, the binary is started with defaults
# start the app 
python3 /app/app.py --database "$DB_NAME" "${server_uri_opt}${SERVER_URI}" 
