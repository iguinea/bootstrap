#!/bin/zsh
function dock_list(){
  docker ps --format json|jq -r '. | [.ID,  .Names, .Image]|@tsv'
  #docker ps --format json|jq -r ' . | [.ID,.Names] '
}
function dock_logs(){
  container=`docker ps --format json | jq --arg name $1 ' . | select( .Names | contains($name) ) '|jq .ID|sed -e 's/\"//g'`
  docker logs -f -n 1000 $container
}
function dock_bash(){

  container=`docker ps --format json | jq --arg name $1 ' . | select( .Names | contains($name) ) '|jq .ID|sed -e 's/\"//g'`
  docker exec -it $container /bin/bash

}
function dock_zsh(){
  container=`docker ps --format json | jq --arg name $1 ' . | select( .Names | contains($name) ) '|jq .ID|sed -e 's/\"//g'`
  docker exec -it $container /bin/zsh
}

function dock_exec(){
  container=`docker ps --format json | jq --arg name $1 ' . | select( .Names | contains($name) ) '|jq .ID|sed -e 's/\"//g'`
  shift;
  echo "docker exec -it $container $*"
  docker exec -it $container $*
}
function dock_cxbagent(){
  container=`docker ps --format json | jq --arg name agent ' . | select( .Names | contains($name) ) '|jq .ID|sed -e 's/\"//g'`
  echo "Container="$container
  docker exec -it $container /bin/bash -c "sudo su - cxbagent -c /opt/cxbagent/cxbagent"
}
function dock_export_2375(){
#docker run -d -v /var/run/docker.sock:/var/run/docker.sock -p 127.0.0.1:1234:1234 bobrik/socat TCP-LISTEN:1234,fork UNIX-CONNECT:/var/run/docker.sock
  docker run -d -v /var/run/docker.sock:/var/run/docker.sock -p 127.0.0.1:2375:2375 bobrik/socat TCP-LISTEN:2375,fork UNIX-CONNECT:/var/run/docker.sock
}
