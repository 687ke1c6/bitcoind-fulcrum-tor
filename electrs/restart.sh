#!/bin/bash
set -e

# Map Dojo network name to electrs network name
case "$COMMON_BTC_NETWORK" in
  testnet ) ELECTRS_NETWORK=testnet; P2P_PORT=18333 ;;
  *       ) ELECTRS_NETWORK=bitcoin; P2P_PORT=8333 ;;
esac

# electrs fetches blocks over P2P, so bitcoind must accept inbound connections
if [ "$BITCOIND_LISTEN_MODE" != "on" ]; then
  echo "WARNING: BITCOIND_LISTEN_MODE is not 'on' - electrs cannot reach bitcoind P2P on $BITCOIND_IP:$P2P_PORT" >&2
fi

# electrs only accepts 'auth' from a config file (not CLI/env), otherwise it
# falls back to bitcoind's cookie file. Write a private config at startup.
if [ -z "$BITCOIND_RPC_USER" ] || [ -z "$BITCOIND_RPC_PASSWORD" ]; then
  echo "ERROR: BITCOIND_RPC_USER / BITCOIND_RPC_PASSWORD not set (is conf/docker-bitcoind.conf in env_file?)" >&2
  exit 1
fi

toml_escape() { local s=${1//\\/\\\\}; printf '%s' "${s//\"/\\\"}"; }

ELECTRS_CONF=$(mktemp /tmp/electrs.XXXXXX.toml)
chmod 600 "$ELECTRS_CONF"
printf 'auth = "%s:%s"\n' "$(toml_escape "$BITCOIND_RPC_USER")" "$(toml_escape "$BITCOIND_RPC_PASSWORD")" > "$ELECTRS_CONF"

electrs_options=(
  --conf "$ELECTRS_CONF"
  --skip-default-conf-files
  --network "$ELECTRS_NETWORK"
  --db-dir "$INDEXER_HOME/db"
  --daemon-rpc-addr "$BITCOIND_IP:$BITCOIND_RPC_PORT"
  --daemon-p2p-addr "$BITCOIND_IP:$P2P_PORT"
  --electrum-rpc-addr "0.0.0.0:50001"
  --monitoring-addr "0.0.0.0:4224"
  --log-filters INFO
)

exec electrs "${electrs_options[@]}"
