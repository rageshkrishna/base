#!/bin/bash -e

# Indicates if docker service should be restarted
export docker_restart=false
readonly DOCKER_VERSION=1.12.1-0~trusty

docker_install() {
  echo "Installing docker"

  apt-get install -y linux-image-extra-`uname -r` linux-image-extra-virtual

  apt-get install -y docker-engine=$DOCKER_VERSION
}

check_docker_opts() {
  echo "Checking docker options"

  SHIPPABLE_DOCKER_OPTS='DOCKER_OPTS="$DOCKER_OPTS -H unix:///var/run/docker.sock -g=/data --storage-driver aufs"'
  opts_exist=$(sh -c "grep '$SHIPPABLE_DOCKER_OPTS' /etc/default/docker || echo ''")

  if [ -z "$opts_exist" ]; then
    ## docker opts do not exist
    echo "appending DOCKER_OPTS to /etc/default/docker"
    sh -c "echo '$SHIPPABLE_DOCKER_OPTS' >> /etc/default/docker"
    docker_restart=true
  else
    echo "Shippable docker options already present in /etc/default/docker"
  fi

  ## remove the docker option to listen on all ports
  echo "Disabling docker tcp listener"
  sh -c "sed -e s/\"-H tcp:\/\/0.0.0.0:4243\"//g -i /etc/default/docker"
}

restart_docker_service() {
  echo "checking if docker restart is necessary"
  if [ $docker_restart == true ]; then
    echo "restarting docker service on reset"
    service docker restart
  else
    echo "docker_restart set to false, not restarting docker daemon"
  fi
}

main() {
  {
    check_docker=$(service --status-all 2>&1 | grep docker)
  } || {
    true
  }
  if [ ! -z "$check_docker" ]; then
    echo "Docker already installed, skipping."
    return
  fi

  docker_install
  check_docker_opts
  restart_docker_service
}

main
