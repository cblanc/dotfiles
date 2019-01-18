#!/usr/bin/env bash

# Load machine specific profile and bashrc
[[ -f ~/.profile ]] && source ~/.profile

source ./exports
source ./path
source ./func
source ./aliases
source ./prompt

