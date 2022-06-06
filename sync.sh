#!/bin/bash

if test -z $1; then
    printf '%s\n' "Missing remote server ip for the first argument." >&2
    exit 1
fi

scp -r * root@$1:/root/
ssh root@$1 bash -c "./run.sh"
