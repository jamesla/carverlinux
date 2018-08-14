#!/usr/bin/env bash
set -xe

# Run Tests
docker run --rm -it \
       -v $PWD:/home/molecule/working:ro \
       -v /var/run/docker.sock:/var/run/docker.sock \
       -w /home/molecule/working \
       -e IS_TRAVIS \
       jamesla/molecule \
       sudo molecule test
