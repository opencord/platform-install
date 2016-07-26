#!/usr/bin/env bash

mkdir -p ~/docker_logs
rm -rf ~/docker_logs/*

for container in `docker ps --format "{{.Names}}"`;
do
  docker logs $container > ~/docker_logs/$container.log 2>&1;
done

cp  ~/service-profile/cord-pod/*.out ~/docker_logs

