#!/bin/bash
# GabeOS ISO Build Script
# Author: thesomewhatyou (GabrielDPP)
#
# This script builds a GabeOS-themed Arch-based ISO using mkarchiso and Calamares
if [[ $EUID -ne 0 ]]; then

  echo "You must be root to execute this script"

  exit 1

fi




mkarchiso -v -w /tmp/ht-archiso -r -P .
