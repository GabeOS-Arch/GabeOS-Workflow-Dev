#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "You must be root to execute this script"
  exit 1
fi

mkarchiso -v -w /tmp/ht-archiso -r -P .
