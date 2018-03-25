#!/usr/bin/env bash

VERSION=`date +%y.%m.%d`
packer build -var 'VERSION=$VERSION' packer.json
