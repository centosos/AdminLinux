#!/bin/bash

set -u
set -e

if groups $PAM_USER | grep -qv admin; then
  if (( `date +%u` >= 6 )); then
    exit 1
  fi
fi

exit 0
