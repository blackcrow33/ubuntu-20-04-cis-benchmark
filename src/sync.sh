#!/bin/bash

helpFunction()
{
   echo ""
   echo "Usage: $0 -s 192.168.1.2 -r disable -e production -f enable"
   echo -e "\t [*] - means default value"
   echo -e "\t-s The remote server ip of the target system. [required]"
   echo -e "\t-r The option indicator that defines whether enables target system to allow to receive syslog by 514 port or not. (*disable|enable)"
   echo -e "\t-e The environment that tells the script will load variables in the file \"settings.<env>\". (*production|staging)"
   echo -e "\t-f The option indicator that defines whether enable log forwarding to the central log server or not. (*enable|disable)"
   echo -e "\t-u The option indicator that defines whether upgrade packages or not (*disable|enable)"
   exit 0 # Exit script after printing help
}

SRV_IP=""
RECV_SYSLOG="disable"
ENVIR="production"
FORWARD="enable"
UPGRADE="disable"

# extracted provided argument if found.
while getopts "s:r:e:f:u:" opt; do
    case "$opt" in 
        s ) SRV_IP="$OPTARG" ;;
        r ) RECV_SYSLOG="$OPTARG" ;;
        e ) ENVIR="$OPTARG" ;;
        f ) FORWARD="$OPTARG" ;;
        f ) UPGRADE="$OPTARG" ;;
        ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
    esac
done

if test -z "$SRV_IP"; then
    printf '%s\n' "Missing target server ip." >&2
    helpFunction
    exit 1
fi

if [ "$ENVIR" != "staging" -a "$ENVIR" != "production" ]; then
    printf '%s\n' "Invalid environment option. (production|staging)" >&2
    helpFunction
    exit 1
fi

if [ "$RECV_SYSLOG" != "disable" -a "$RECV_SYSLOG" != "enable" ]; then
    printf '%s\n' "Invalid receive syslog option. (disable|enable)" >&2
    helpFunction
    exit 1
fi

if [ "$FORWARD" != "disable" -a "$FORWARD" != "enable" ]; then
    printf '%s\n' "Invalid forward syslog option. (enable|disable)" >&2
    helpFunction
    exit 1
fi

if [ "$UPGRADE" != "disable" -a "$UPGRADE" != "enable" ]; then
    printf '%s\n' "Invalid upgrade option. (enable|disable)" >&2
    helpFunction
    exit 1
fi

echo "Copying the required file into the /root path"
scp -qr cis/ root@$SRV_IP:/root
echo "Start run the script with the environment \"$ENVIR\"..."
ssh root@$SRV_IP bash -c "/root/cis/run.sh $ENVVIR $RECV_SYSLOG $FORWARD $UPGRADE"
exit 0
