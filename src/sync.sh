#!/bin/bash

helpFunction()
{
   echo ""
   echo "Usage: $0 [-s|--server] 192.168.1.2 [-e|--environment] production [-u|--upgrade] [-r|--syslog]"
   echo -e "\t [*] - means default value"
   echo -e "\t-s | --server: The remote server ip of the target system. [required]"
   echo -e "\t-e | --environment: The environment that tells the script will load variables in the file \"settings.<env>\". (*production|staging)"
   echo -e "\t-r | --syslog: The option indicator that defines whether enables target system to allow to receive syslog by 514 port or not. (*disable|enable)"
   echo -e "\t-u | --upgrade: The option indicator that defines whether upgrade packages or not (*disable|enable)"
   echo -e "\t-k | --keep-firewall: The option indicator that defines whether keep the firewall rules or not (*no|yes)"
   exit 0 # Exit script after printing help
}

SRV_IP=""
RECV_SYSLOG="disable"
ENVIR="production"
FORWARD="enable"
UPGRADE="disable"
KEEP_FIREWALL="no"

PARSED_ARGUMENTS=$(getopt -o s:e:ruk --long upgrade,syslog,keep-firewall,server:,environment: -- "$@")

while true; do
    case "$1" in
        -s|--server ) SRV_IP="$2"; shift 2 ;;
        -e|--environment ) ENVIR="$2"; shift 2 ;;
        -u|--upgrade ) UPGRADE="enable"; shift 1;;
        -r|--syslog ) FORWARD="disable"; RECV_SYSLOG="enable"; shift 1;;
        -k|--keep-firewall) KEEP_FIREWALL="yes"; shift 1;;
        --|"" ) shift; break ;;
        * ) helpFunction;  break ;; # Print helpFunction in case parameter is non-existent
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

if [ "$KEEP_FIREWALL" != "yes" -a "$KEEP_FIREWALL" != "no" ]; then
    printf '%s\n' "Invalid keep firewall option. (yes|no)" >&2
    helpFunction
    exit 1
fi

echo "Copying the required file into the /root path"
scp -qr cis/ root@$SRV_IP:/root
echo "Start run the script with the environment \"$ENVIR\"..."
ssh root@$SRV_IP ENVIR=$ENVIR RECV_SYSLOG=$RECV_SYSLOG FORWARD=$FORWARD UPGRADE=$UPGRADE KEEP_FIREWALL=$KEEP_FIREWALL /root/cis/run.sh
exit 0
