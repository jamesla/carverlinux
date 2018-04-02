#!/usr/bin/env bash

VERSION=`date +%Y.%m.%d`
packer build -only=parallels-iso -var version=$VERSION packer.json
