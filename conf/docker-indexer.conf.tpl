#########################################
# CONFIGURATION OF A LOCAL INDEXER
#########################################

# Install and run a local indexer inside Docker
# Set this option to 'off' for using an indexer hosted outside of Docker
# or when using a different data source (local bitcoind, OXT)
# Value: on | off
INDEXER_INSTALL=on

# Choice which Indexer you would like to install:
# Fulcrum - fast indexer, can be used as Electrum server for personal use - takes a 2-3 days to index
# electrs - lightweight Electrum server (romanz/electrs), lower disk usage than Fulcrum
# Value: fulcrum | electrs
INDEXER_TYPE=fulcrum

# Expose the electrum API to external apps
# Has effect only if INDEXER_TYPE=fulcrum or electrs
# Warning: Do not expose your electrum API to internet!
# See INDEXER_EXTERNAL_IP
# Value: on | off
INDEXER_EXTERNAL=off

# IP address used to expose the electrum API to external apps
# This parameter is inactive if INDEXER_EXTERNAL isn't set to 'on'
# Warning: Do not expose your RPC API to internet!
# Recommended value:
#   linux: 127.0.0.1
#   macos or windows: IP address of the VM running the docker host
# Type: string
INDEXER_EXTERNAL_IP=127.0.0.1

