#!/bin/bash

# Use Docker buildkit
export DOCKER_BUILDKIT=1

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

get_docker_compose() {
  echo "docker compose"
}

docker_compose=$(get_docker_compose)

# Source a file
source_file() {
  if [ -f $1 ]; then
    source $1
  elif [ -f "$1.tpl" ]; then
    source "$1.tpl"
  else
    echo "Unable to find file $1"
  fi
}

# Source config files
source_file "$DIR/conf/docker-indexer.conf"
source_file "$DIR/conf/docker-bitcoind.conf"
source_file "$DIR/.env"

# Validate indexer selection
if [ "$INDEXER_INSTALL" == "on" ]; then
  case "$INDEXER_TYPE" in
    fulcrum|electrs ) ;;
    * ) echo "Unsupported INDEXER_TYPE '$INDEXER_TYPE' (expected: fulcrum | electrs)" >&2; exit 1 ;;
  esac
fi

# Export some variables for compose
export BITCOIND_RPC_EXTERNAL_IP INDEXER_EXTERNAL_IP TOR_SOCKS_PORT

# Select YAML files
select_yaml_files() {
  yamlFiles="-f $DIR/docker-compose.yaml"

  if [ "$BITCOIND_INSTALL" == "on" ]; then
    yamlFiles="$yamlFiles -f $DIR/services/bitcoind.install.yaml"

    if [ "$BITCOIND_RPC_EXTERNAL" == "on" ]; then
      yamlFiles="$yamlFiles -f $DIR/services/bitcoind.rpc.expose.yaml"
    fi
  fi

  if [ "$INDEXER_INSTALL" == "on" ]; then
    case "$INDEXER_TYPE" in
      fulcrum|electrs )
        yamlFiles="$yamlFiles -f $DIR/services/$INDEXER_TYPE.install.yaml"
        if [ "$INDEXER_EXTERNAL" == "on" ]; then
          yamlFiles="$yamlFiles -f $DIR/services/$INDEXER_TYPE.port.expose.yaml"
        fi
        ;;
    esac
  fi

  for o in "$DIR"/overrides/*.yaml; do
    [ -f "$o" ] && yamlFiles="$yamlFiles -f $o"
  done

  # Return yamlFiles
  echo "$yamlFiles"
}

# Docker build
docker_build() {
  yamlFiles=$(select_yaml_files)
  eval "$docker_compose $yamlFiles build --parallel $@"
}

# Docker up
docker_up() {
  yamlFiles=$(select_yaml_files)
  echo "$docker_compose $yamlFiles up $@ -d"
  eval "$docker_compose $yamlFiles up $@ -d"
}

# Start
start() {
  # Check if dojo is running (check the db container)
  isRunning=$(docker inspect --format="{{.State.Running}}" tor 2> /dev/null)

  if [ $? -eq 1 ] || [ "$isRunning" == "false" ]; then
    echo "Starting Dojo. Please wait."
    docker_up --remove-orphans
  else
    echo "Dojo is already running."
  fi
}

# Stop
stop() {
  echo "Preparing shutdown of Dojo. Please wait."
  # Check if dojo is running (check the db container)
  isRunning=$(docker inspect --format="{{.State.Running}}" tor 2> /dev/null)
  if [ $? -eq 1 ] || [ "$isRunning" == "false" ]; then
    echo "Dojo is already stopped."
    exit
  fi
  # Renewal of bitcoind onion address
  if [ "$BITCOIND_INSTALL" == "on" ] && [ "$BITCOIND_LISTEN_MODE" == "on" ] && [ "$BITCOIND_EPHEMERAL_HS" = "on" ]; then
    docker exec -it tor rm -rf /var/lib/tor/hsv3bitcoind &> /dev/null
  fi
  # Stop docker containers
  yamlFiles=$(select_yaml_files)
  eval "$docker_compose $yamlFiles stop"
}

# Restart dojo
restart() {
  stop
  docker_up
}

# Install
install() {
  source "$DIR/install/install-scripts.sh"
  # Initialize the config files
  init_config_files
  # Build and start Dojo
  docker_build --no-cache
  docker_up --remove-orphans
  buildResult=$?
  if [ $buildResult -eq 0 ]; then
    # Display the logs
    if [ $noLog -eq 1 ]; then
      logs "" 0
    fi
  else
    # Return an error
    echo -e "\nInstallation of Dojo failed. See the above error message."
    exit $buildResult
  fi
}

# Delete everything
uninstall() {
  source "$DIR/install/uninstall-scripts.sh"

  auto=1

  # Extract install options from arguments
  if [ $# -gt 0 ]; then
    for option in "$@"
    do
      case "$option" in
        --auto )    auto=0 ;;
        * )         break ;;
      esac
    done
  fi

  # Confirmation
  if [ $auto -eq 0 ]; then
    launchUninstall=0
  else
    get_confirmation
    launchUninstall=$?
  fi

  if [ $launchUninstall -eq 0 ]; then
    yamlFiles=$(select_yaml_files)
    eval "$docker_compose $yamlFiles down --rmi all"
    docker volume prune -f
    return 0
  else
    return 1
  fi
}

# Display the onion addresses
onion() {
  echo " "
  echo "WARNING: Do not share these onion addresses with anyone!"
  echo " "

  if [ "$BITCOIND_INSTALL" == "on" ]; then
    if [ "$BITCOIND_LISTEN_MODE" == "on" ]; then
      V3_ADDR_BTCD=$( docker exec -it tor cat /var/lib/tor/hsv3bitcoind/hostname )
      echo "Your local bitcoind (do not share) = $V3_ADDR_BTCD"
      echo " "
    fi
  fi

  if [ "$INDEXER_INSTALL" == "on" ]; then
    if [ "$INDEXER_TYPE" == "fulcrum" ] || [ "$INDEXER_TYPE" == "electrs" ]; then
      V3_ADDR_INDEXER=$( docker exec -it tor cat /var/lib/tor/hsv3$INDEXER_TYPE/hostname )
      echo "$INDEXER_TYPE hidden service address = $V3_ADDR_INDEXER"
      echo " "
    fi
  fi
}


shift $((OPTIND -1))

subcommand=$1; shift

case "$subcommand" in
  bitcoin-cli )
    if [ "$BITCOIND_INSTALL" == "on" ]; then
      docker exec -it bitcoind bitcoin-cli \
        -rpcconnect=bitcoind \
        --rpcport="$BITCOIND_RPC_PORT" \
        --rpcuser="$BITCOIND_RPC_USER" \
        --rpcpassword="$BITCOIND_RPC_PASSWORD" \
        $1 $2 $3 $4 $5
      else
        echo -e "Command not supported for your setup.\nCause: Your Dojo is using an external bitcoind"
      fi
    ;;
  help )
    help
    ;;
  clean )
    clean
    ;;
  install )
    install "$@"
    ;;
  logs )
    module=$1; shift
    numlines=0

    # Process package options
    while getopts ":n:" opt; do
      case ${opt} in
        n )
          numlines=$OPTARG
          ;;
        \? )
          echo "Invalid Option: -$OPTARG" 1>&2
          exit 1
          ;;
        : )
          echo "Invalid Option: -$OPTARG requires an argument" 1>&2
          exit 1
          ;;
      esac
    done
    shift $((OPTIND -1))

    logs "$module" $numlines
    ;;
  onion )
    onion
    ;;
  restart )
    restart
    ;;
  start )
    start
    ;;
  stop )
    stop
    ;;
  uninstall )
    uninstall "$@"
    ;;
  upgrade )
    upgrade "$@"
    ;;
  version )
    version
    ;;
  build )
    module=$1; shift
    yamlFiles=$(select_yaml_files)
    command="$docker_compose $yamlFiles build $module $@"
    eval "$command"
    ;;
  up )
    module=$1; shift
    yamlFiles=$(select_yaml_files)
    command="$docker_compose $yamlFiles start $module"
    eval "$command"
    ;;
  down )
    module=$1; shift
    yamlFiles=$(select_yaml_files)
    command="$docker_compose $yamlFiles stop $module"
    eval "$command"
    ;;
  bash )
    containerid=`docker ps | grep $1 | awk '{print $1}'`
    if [ ! -z "$containerid" ]; then
      docker exec -it $containerid /bin/bash
    fi
    ;;
  tor )
    tor "$@"
    ;;
  config )
    yamlFiles=$(select_yaml_files)
    command="$docker_compose $yamlFiles config"
    eval "$command"
    ;;
esac
