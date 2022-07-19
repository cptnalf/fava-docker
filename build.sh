#!/bin/bash

SOURCE_BRANCH=1.22.1

DOCKER_BUILDKIT=1 docker build --progress=plain . \
  -t cptnalf/fava:$SOURCE_BRANCH \
  --build-arg SOURCE_BRANCH=$SOURCE_BRANCH
