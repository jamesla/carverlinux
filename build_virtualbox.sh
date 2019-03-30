#!/usr/bin/env bash

VERSION=`date +%Y.%m.%d`
packer build -only=virtualbox-iso -var version=$VERSION packer.json
