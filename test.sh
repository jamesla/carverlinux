#!/usr/bin/env bash
set -xe

# Run Tests
docker run --rm \
       -v $PWD:/home/molecule/working:ro \
       -v /var/run/docker.sock:/var/run/docker.sock \
       -w /home/molecule/working \
       jamesla/molecule \
       sudo molecule test
