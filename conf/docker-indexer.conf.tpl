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

#
# SYSTEM SETTINGS
# Do not modify after the first install
#

FULCRUM_VERSION_TAG=1.11.1
ELECTRS_VERSION_TAG=0.0.1

# Shared by fulcrum and electrs
INDEXER_LINUX_UID=1133
INDEXER_LINUX_GID=1136
