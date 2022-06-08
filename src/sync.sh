#!/bin/bash

if test -z $1; then
    printf '%s\n' "Missing remote server ip for the first argument." >&2
    exit 1
fi

ENV=production
if [ -n "$2" -a \( "$2" == "staging" -o "$2" == "production" \) ]; then
    ENV=$2
elif [ -n "$2" -a \( "$2" != "staging" -a "$2" != "production" \) ]; then
    printf '%s\n' "Invalid environment option for the second argument." >&2
    exit 1
fi

echo "Copying the required file into the /root path"
scp -qr cis/ root@$1:/root
echo "Start run the script with the environment \"$ENV\"..."
ssh root@$1 bash -c "echo $ENV && /root/cis/run.sh $ENV"

exit 0
