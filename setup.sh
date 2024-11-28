set -e

COLOR_RED_BRIGHT='\033[1;31m'
COLOR_GREEN_BRIGHT='\033[1;32m'
COLOR_BLUE_BRIGHT='\033[1;34m'
NO_COLOR='\033[0m' # No Color

#### Default values for environment variables

COMPOSE_PROJECT_NAME="nifi-opendatalab2"
COMPOSE_USER=1000
COMPOSE_GRP=1000
COMPOSE_NETWORKNAME="nifi-opendatalab2"

# Taefik

TRAEFIK_IMAGE_NAME=traefik
TRAEFIK_ACTIVE_BRANCH="v3.0"
TRAEFIK_NAME="proxy.opendatalab2.uhu.es"
TRAEFIK_HTTP_PORT="80"
TRAEFIK_HTTPS_PORT="443"
TRAEFIK_LOG_LEVEL="DEBUG"
TRAEFIK_ENABLE_DASHBOARD="true"

# Creenciales de administrador para acceder al dashboard de traefik. Por defecto son
# admin:password. Las puede cambiar ejectando el siguiente comando indicando un nuevo usuario y clave
#
# htpasswd -nb admin password
TRAEFIK_ADMIN_USER="admin"
TRAEFIK_ADMIN_PASSWORD='$apr1$CBkxfGFG$15w43pPGtrIDwtydX8e7O0'

# NIfi

NIFI_IMAGE_NAME=apache/nifi
NIFI_ACTIVE_BRANCH="v3.0"
NIFI_NAME=nifi.opendatalab2.uhu.es
NIFI_WEB_HTTP_PORT=8080
NIFI_WEB_HTTPS_PORT=8443
NIFI_SINGLE_USER_CREDENTIALS_USERNAME=admin
NIFI_SINGLE_USER_CREDENTIALS_PASSWORD=ctsBtRBKHRAx69EqUghvvgEvjnaLjFEB


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

prepare_config() {
  load_dotenv
  check_required_env_variables

  fragments+=("base")


  aggregate_compose_files
}

start() {
  print_info "Compose files: ${compose_files[*]}"
  print_info "Traefik dashboard will be listening in https://${PROXY_NAME}:${HTTPS_PORT}/dashboard/. User credentials are stored in /etc/traefik/dynamic_conf.yml file"
  docker compose "${compose_files[@]}" up --remove-orphans
}

start_detached() {
  print_info "Compose files: ${compose_files[*]}"
  print_info "Traefik dashboard will be listening in https://${PROXY_NAME}:${HTTPS_PORT}/dashboard/. User credentials are stored in /etc/traefik/dynamic_conf.yml file"
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
  print_info "Running a shell in a new traefik container"
  docker compose "${compose_files[@]}" run --rm traefik /bin/sh
}

docker_connect() {
  print_info "Executing a shell in traefik container"
  docker compose "${compose_files[@]}" exec -it traefik /bin/sh
} 


show_help() {
  echo "Usage: $(basename $0) [ARGUMENTS]"
  echo "arguments:"
  echo "  start      Inicia start "
  echo "  start-i    Inicia start interactivo "
  echo "  stop       Destrute stack"
  echo "  logs       Muestra los logs en el stack"
  echo "  shell      Ejecuta una shell en un nuevo contenedor trapper"
  echo "  connect    Se conecta a la instancia en execucion en trapper"
  echo "  restart    Reinicia el stack"

  # Add more options and descriptions as needed
  exit 0
}


main() {
  local cmd=$1

  prepare_config
  export_image_tags

  if [ "$cmd" = "start" ]; then
    # obtain_images
    generate_autosign_ssl_cert ${NIFI_NAME}
    generate_autosign_ssl_cert ${TRAEFIK_NAME}
    start_detached
  elif [ "$cmd" = "start-i" ]; then
    # obtain_images
    generate_autosign_ssl_cert ${NIFI_NAME}
    generate_autosign_ssl_cert ${TRAEFIK_NAME}
    start
  elif [ "$cmd" = "stop" ]; then
    stop
  elif [ "$cmd" = "logs" ]; then
    logs
  elif [ "$cmd" = "shell" ]; then
    generate_autosign_ssl_certs
    docker_shell
  elif [ "$cmd" = "connect" ]; then
    docker_connect    
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