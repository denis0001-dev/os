#!/bin/bash

cd "$(dirname "$0")" || exit

target=$1
if [[ -z $target ]]; then
  echo "ERROR: Target not specified. Available options: build-container, build." > /dev/stderr
  exit 1
fi
case $target in
  build-container)
    docker build -t os .
    exit $?
    ;;
  build)
    set -- "${@:2}"
    make_targets=$*
    if [[ -z $make_targets ]]; then
      docker run --mount type=bind,src=.,dst=/root/os -it os
    else
      docker run --mount type=bind,src=.,dst=/root/os -it os /bin/bash -c "cd /root/os/ && make $make_targets"
    fi
    ;;
  build-run)
    $0 build
    make qemu-nocompile
    ;;
  *)
    echo "ERROR: unknown target specified." > /dev/stderr
    exit 1
    ;;
esac