#!/usr/bin/env bash
set -xe

# Run Tests
docker run --rm -it \
       -v $PWD:/home/molecule/working:ro \
       -v /var/run/docker.sock:/var/run/docker.sock \
       -w /home/molecule/working \
       quay.io/ansible/molecule:3.0.8 \
       molecule test
