#!/usr/bin/env bash

VERSION=`date +%Y.%m.%d`
packer build -only=qemu -var version=$VERSION packer.json
