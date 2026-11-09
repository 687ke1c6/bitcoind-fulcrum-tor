#
# EXPERT AND DEV SETTINGS
#


#
# NETWORK ENVIRONMENT
#

# Select a Bitcoin network
# Do not modify this value after the first install
# Value: mainnet | testnet
COMMON_BTC_NETWORK=mainnet

#
# GLOBAL
#

COMPOSE_CONVERT_WINDOWS_PATHS=1

# Version advertised in the bitcoind user agent comment
VERSION_TAG=1.22.0


#
# NETWORKING
# Static IPs of each container on the internal docker network
#

NET_TOR_IPV4=172.28.1.4
NET_BITCOIND_IPV4=172.28.1.5
NET_INDEXER_IPV4=172.28.1.6
