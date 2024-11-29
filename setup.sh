#!/bin/bash

set -e

COLOR_RED_BRIGHT='\033[1;31m'
COLOR_GREEN_BRIGHT='\033[1;32m'
COLOR_BLUE_BRIGHT='\033[1;34m'
NO_COLOR='\033[0m' # No Color

#### Default values for environment variables

export COMPOSE_PROJECT_NAME="nifi-opendatalab2"
export COMPOSE_USER=1000
export COMPOSE_GRP=1000
export COMPOSE_NETWORKNAME="nifi-opendatalab2"
export COMPOSE_MOUNT_VOLUMES=1

# Taefik

export TRAEFIK_IMAGE_NAME=traefik
export TRAEFIK_ACTIVE_BRANCH="v3.0"
export TRAEFIK_NAME="proxy.opendatalab2.uhu.es"
export TRAEFIK_HTTP_PORT="80"
export TRAEFIK_HTTPS_PORT="443"
export TRAEFIK_LOG_LEVEL="DEBUG"
export TRAEFIK_ENABLE_DASHBOARD="true"

export TRAEFIK_ADMIN_USER="admin"
export TRAEFIK_ADMIN_PASSWORD='$apr1$CBkxfGFG$15w43pPGtrIDwtydX8e7O0'

# NIfi

export NIFI_IMAGE_NAME=apache/nifi
export NIFI_ACTIVE_BRANCH="2.0.0"
export NIFI_NAME=nifi.opendatalab2.uhu.es
export NIFI_WEB_HTTP_PORT=8080
export NIFI_WEB_HTTPS_PORT=8443
export NIFI_SINGLE_USER_CREDENTIALS_USERNAME=admin
export NIFI_SINGLE_USER_CREDENTIALS_PASSWORD=ctsBtRBKHRAx69EqUghvvgEvjnaLjFEB
export NIFI_VOLUMES_DIR=../data/nifi

# mariadb
export MARIADB_IMAGE_NAME=mariadb
export MARIADB_ACTIVE_BRANCH="10.5"
export MARIADB_NAME=mariadb.opendatalab2.uhu.es
export MARIADB_PORT=3306
export MARIADB_ROOT_PASSWORD=ctsBtRBKHRAx69EqUghvvgEvjnaLjFEB
export MARIADB_VOLUMES_DIR="../data/mariadb"

# phpmyadmin
export PM_IMAGE_NAME=phpmyadmin/phpmyadmin
export PM_ACTIVE_BRANCH="5.1"
export PM_NAME=phpmyadmin.opendatalab2.uhu.es

# mongo
export MONGO_IMAGE_NAME=mongo
export MONGO_ACTIVE_BRANCH="4.4"
export MONGO_NAME=mongo.opendatalab2.uhu.es
export MONGO_INITDB_ROOT_USERNAME=root   # Usuario administrador para MongoDB
export MONGO_INITDB_ROOT_PASSWORD=example # Contraseña del usuario administrador
export MONGO_VOLUMES_DIR=../data/mongo

# mongo-express
export ME_IMAGE_NAME=mongo-express
export ME_ACTIVE_BRANCH="0.54"
export ME_NAME=mongo-express.opendatalab2.uhu.es

#### End Default values for environment variables

# Global variables
fragments=()

# Utility functions

load_dotenv() {
  if [ -f .env ]; then
    print_info "Loading environment variables from .env file..."
    . .env
  else
    print_info "No .env file, skipping..."
  fi
}

print_err() {
  echo -e "${COLOR_RED_BRIGHT}[ERROR]${NO_COLOR} $1"
  exit 1
}
print_ok() {
  echo -e "${COLOR_GREEN_BRIGHT}[OK]${NO_COLOR} $1"
}
print_info() {
  echo -e "${COLOR_BLUE_BRIGHT}[INFO]${NO_COLOR} $1"
}

print_warn() {
  echo -e "${COLOR_RED_BRIGHT}[WARN]${NO_COLOR} $1"
}

# Deployment functions


pull_images() {
#  docker pull "${IMAGE_NAME}:${IMAGE_TAG_WORKER}"
  docker compose "${compose_files[@]}" pull
}

export_image_tags() {
  export IMAGE_TAG_WORKER=$ACTIVE_BRANCH
}

obtain_images() {
  print_info "Images will be pulled from Docker registry"
  pull_images
}

check_required_env_var() {
  local var=$1
  if [ -n "${!var}" ]; then
    print_ok "$var set"
  else
    print_err "Required environment variable $var not present, aborting"
  fi
}

check_required_env_variables() {
  required_vars=()

  print_info "Checking basic configuration"
  for var in "${required_vars[@]}"; do
    check_required_env_var "$var"
    export "${var?}"
  done
}

generate_autosign_ssl_cert()
{
  print_info "Generating autosign ssl cert for $1"

  if [ -f "etc/traefik/certs/"$1".key" ]; then
    print_warn "Certificate for $1 already exists"
  else
    openssl req -x509 -newkey rsa:4096 -keyout etc/traefik/certs/"$1".key -out etc/traefik/certs/"$1".crt -sha256 -days 3650 -nodes -subj "/C=ES/ST=Huelva/L=Huelve/O=University of Huelva/OU=DCI/CN=$1"
  fi
}

compose_files=()
aggregate_compose_files() {
  for fragment in "${fragments[@]}"; do
    compose_files+=("-f" "docker/docker-compose.${fragment}.yml")
  done
}

configure_volumes() {
  if [ "${COMPOSE_MOUNT_VOLUMES}" = 1 ]; then

    if [ -z "$VOLUMES_DIR" ]; then
      VOLUMES_DIR="$(pwd)/volumes"
      print_warn "VOLUMES_DIR not set, defaulting to ${VOLUMES_DIR}"
    fi

    print_ok "Mounting volumes to ${VOLUMES_DIR}"
    export VOLUMES_DIR
    fragments+=("volumes")
  else
    print_warn "Using named volumes for storing data"
  fi
}

prepare_config() {
  load_dotenv
  check_required_env_variables
  fragments+=("base")
  #configure_volumes
  aggregate_compose_files
}

start() {
  print_info "Compose files: ${compose_files[*]}"
  print_info "Traefik dashboard will be listening in https://${TRAEFIK_NAME}:${TRAEFIK_HTTPS_PORT}/dashboard/. User credentials are stored in /etc/traefik/dynamic_conf.yml file"
  docker compose "${compose_files[@]}" up --remove-orphans
}

start_detached() {
  print_info "Compose files: ${compose_files[*]}"
  print_info "Traefik dashboard will be listening in https://${TRAEFIK_NAME}:${TRAEFIK_HTTPS_PORT}/dashboard/. User credentials are stored in /etc/traefik/dynamic_conf.yml file"
  docker compose "${compose_files[@]}" up -d --remove-orphans
}

stop() {
  docker compose "${compose_files[@]}" down --remove-orphans
}

restart() {
  docker compose "${compose_files[@]}" restart
}

logs() {
  docker compose "${compose_files[@]}" logs -f
}

docker_shell() {
  container="traefik"

  if [ "$#" -eq 2 ]; then
    container=$2
  fi

  print_info "Running a shell in a new ${container} container"
  docker compose "${compose_files[@]}" run --rm ${container} /bin/sh
}

docker_connect() {
  container="traefik"

  echo $#
  if [ "$#" -eq 2 ]; then
    container=$2
  fi

  print_info "Executing a shell in ${container} container"
  docker compose "${compose_files[@]}" exec -it ${container} /bin/sh
} 

create_volumns() {
  script_dir=$(realpath $(dirname "$0"))
   mkdir -p "$script_dir"/data/nifi/conf
   mkdir -p "$script_dir"/data/nifi/content
   mkdir -p "$script_dir"/data/nifi/data
   mkdir -p "$script_dir"/data/nifi/db
   mkdir -p "$script_dir"/data/nifi/flowfile
   mkdir -p "$script_dir"/data/nifi/logs
   mkdir -p "$script_dir"/data/nifi/provenance
   mkdir -p "$script_dir"/data/mariadb
   mkdir -p "$script_dir"/data/mongo
}




show_help() {
  echo "Usage: $(basename $0) [ARGUMENTS]"
  echo "arguments:"
  echo "  start      Inicia start "
  echo "  start-i    Inicia start interactivo "
  echo "  stop       Destruye stack"
  echo "  logs       Muestra los logs en el stack"
  echo "  shell      Ejecuta una shell en un nuevo contenedor de traefik"
  echo "  connect    Se conecta a la instancia en ejecución de traefik"
  echo "  restart    Reinicia el stack"

  # Add more options and descriptions as needed
  exit 0
}


main() {
  local cmd=$1

  prepare_config
  export_image_tags
  create_volumns
  
  if [ "$cmd" = "start" ]; then
    # obtain_images
    generate_autosign_ssl_cert ${NIFI_NAME}
    generate_autosign_ssl_cert ${TRAEFIK_NAME}
    generate_autosign_ssl_cert ${PM_NAME}
    generate_autosign_ssl_cert ${ME_NAME}

    start_detached
  elif [ "$cmd" = "start-i" ]; then
    # obtain_images
    generate_autosign_ssl_cert ${NIFI_NAME}
    generate_autosign_ssl_cert ${TRAEFIK_NAME}
    generate_autosign_ssl_cert ${PM_NAME}
    generate_autosign_ssl_cert ${ME_NAME}

    start
  elif [ "$cmd" = "stop" ]; then
    stop
  elif [ "$cmd" = "logs" ]; then
    logs
  elif [ "$cmd" = "shell" ]; then
    docker_shell "$@"
  elif [ "$cmd" = "connect" ]; then
    docker_connect "$@"
  elif [ "$cmd" = "restart" ]; then
    restart 
  elif [ "$cmd" = "help" ]; then
    restart
  else
    print_err "Invalid command: ${cmd}"
    show_help
  fi
}

if [[ "$1" == "-h" || "$1" == "--help"  || "$#" -eq 0 ]]; then
  show_help
fi

main "$@"
