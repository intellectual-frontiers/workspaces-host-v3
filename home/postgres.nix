{ pkgs, lib, ... }:

let
  # ~/.pgpass holds real credentials, so - like home/workspaces.nix's
  # mgit.json - home-manager only creates it once (mode 0600, which
  # libpq itself requires or it silently ignores the file) and never
  # touches an existing one again. This stub has no real secrets, just
  # the format documentation `pgpass --help` also prints.
  pgpassStub = pkgs.writeText "pgpass.stub" ''
    # See https://www.postgresql.org/docs/current/libpq-pgpass.html and
    # `pgpass --help` (pkgs/pgpass) for how this file is used.
    #
    # Before each connection line, add a descriptor comment:
    #   # { id: "MYDB", description: "Purpose", boundary: "Network" }
    #   hostname:port:database:username:password
    #
    # Example (uncomment and edit, or add your own below):
    # # { id: "MY_SPECIAL_DB", description: "Human-friendly description", boundary: "Network" }
    # 192.168.2.24:5432:pgDB_name:pgDB_username:sup3rSecure!
  '';
in
{
  # Plain psql client config - no secrets - so it's fully managed here
  # like any other dotfile in this repo.
  home.file.".psqlrc".text = ''
    ------------------------------------------------------------------------------
    -- sources and inspiration:
    -- * https://github.com/rafi/etc-skel/blob/master/.config/psql/config
    -- * http://opensourcedbms.com/dbms/psqlrc-psql-startup-file-for-postgres/
    -- * http://www.craigkerstiens.com/2013/02/21/more-out-of-psql/
    -- * https://github.com/dlamotte/dotfiles/blob/master/psqlrc
    ------------------------------------------------------------------------------

    \set QUIET ON

    -- Colored prompt that looks like `(user@host:port) database> `
    \set PROMPT1 '%[%033[2;5;27m%]%(%n@%M:%>)%[%033[0m%] %001%[%033[1;33;40m%]%002%/%001%[%033[0m%]> '

    -- PROMPT2 is printed when the prompt expects more input, like when you type
    -- SELECT * FROM<enter>. %R shows what type of input it expects.
    \set PROMPT2 '[more] %R > '

    -- Use best available output format
    \x auto

    \set VERBOSITY verbose
    \set HISTFILE ~/.psql_history- :DBNAME
    \set HISTCONTROL ignoredups
    \set PAGER always
    \set HISTSIZE 2000
    \set ECHO_HIDDEN OFF
    \set COMP_KEYWORD_CASE upper

    \timing
    \encoding unicode

    \pset null '¤'
    \pset linestyle unicode
    \pset border 2

    \pset format wrapped

    \set QUIET OFF

    -- Administration queries

    \set menu '\\i ~/.psqlrc'

    \set settings 'SELECT name, setting,unit,context from pg_settings;'

    \set locks  'SELECT bl.pid AS blocked_pid, a.usename AS blocked_user, kl.pid AS blocking_pid, ka.usename AS blocking_user, a.query AS blocked_statement FROM pg_catalog.pg_locks bl JOIN pg_catalog.pg_stat_activity a ON bl.pid = a.pid JOIN pg_catalog.pg_locks kl JOIN pg_catalog.pg_stat_activity ka ON kl.pid = ka.pid ON bl.transactionid = kl.transactionid AND bl.pid != kl.pid WHERE NOT bl.granted;'

    \set conninfo 'SELECT usename, count(*) from pg_stat_activity group by usename;'

    \set activity 'SELECT datname, pid, usename, application_name,client_addr, client_hostname, client_port, query, state from pg_stat_activity;'

    \set waits 'SELECT pg_stat_activity.pid, pg_stat_activity.query, pg_stat_activity.waiting, now() - pg_stat_activity.query_start AS \"totaltime\", pg_stat_activity.backend_start FROM pg_stat_activity WHERE pg_stat_activity.query !~ \'%IDLE%\'::text AND pg_stat_activity.waiting = true;'

    \set dbsize 'SELECT datname, pg_size_pretty(pg_database_size(datname)) db_size FROM pg_database ORDER BY db_size;'

    \set tablesize 'SELECT nspname || \'.\' || relname AS \"relation\", pg_size_pretty(pg_relation_size(C.oid)) AS "size" FROM pg_class C LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace) WHERE nspname NOT IN (\'pg_catalog\', \'information_schema\') ORDER BY pg_relation_size(C.oid) DESC LIMIT 40;'

    \set uptime 'SELECT now() - pg_postmaster_start_time() AS uptime;'

    -- Development queries:

    \set sp 'SHOW search_path;'
    \set clear '\\! clear;'
    \set ll '\\! ls -lrt;'

    -- vim: set ft=psql ts=2 sw=2 tw=80 et :
  '';

  home.activation.pgpassFile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "$HOME/.pgpass" ]; then
      $DRY_RUN_CMD install -m 600 ${pgpassStub} "$HOME/.pgpass"
    fi
  '';
}
