#!/usr/bin/env bash

# Load machine specific profile and bashrc
[[ -f ~/.profile ]] && source ~/.profile

# Resolve directory to dotfile bash directory
# https://gist.github.com/TheMengzor/968e5ea87e99d9c41782<Paste>
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DOTFILE_BASH_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
export DOTFILE_BASH_DIR

DOTFILE_DIR="$(dirname "$DOTFILE_BASH_DIR")"
export DOTFILE_DIR

source "${DOTFILE_BASH_DIR}/exports"
source "${DOTFILE_BASH_DIR}/path"
source "${DOTFILE_BASH_DIR}/func"
source "${DOTFILE_BASH_DIR}/aliases"
source "${DOTFILE_BASH_DIR}/prompt"

