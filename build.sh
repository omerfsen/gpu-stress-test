#!/bin/bash

if [[ ! -z ${1} ]]
then
  docker build --platform linux/amd64 -f Dockerfile . -t gpu-stress-test:${1}
fi

