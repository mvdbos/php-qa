#!/usr/bin/env bash

proxy_ip=$(docker network inspect bridge | grep Gateway | awk '{print $2;}'| tr -d \")
echo $proxy_ip

docker build \
    --build-arg http_proxy=http://$proxy_ip:3128 \
    --build-arg https_proxy=http://$proxy_ip:3128 \
    "$@"
