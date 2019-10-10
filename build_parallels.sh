#!/usr/bin/env bash

VERSION=`date +%Y.%m.%d`
packer build -on-error=ask -only=parallels-iso -var version=$VERSION packer.json 
