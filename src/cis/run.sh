#!/bin/bash

export RCol='\e[0m'    # Text Reset

# Regular           Bold                Underline           High Intensity      BoldHigh Intens     Background          High Intensity Backgrounds
Bla='\e[0;30m';     BBla='\e[1;30m';    UBla='\e[4;30m';    IBla='\e[0;90m';    BIBla='\e[1;90m';   On_Bla='\e[40m';    On_IBla='\e[0;100m';
Red='\e[0;31m';     BRed='\e[1;31m';    URed='\e[4;31m';    IRed='\e[0;91m';    BIRed='\e[1;91m';   On_Red='\e[41m';    On_IRed='\e[0;101m';
Gre='\e[0;32m';     BGre='\e[1;32m';    UGre='\e[4;32m';    IGre='\e[0;92m';    BIGre='\e[1;92m';   On_Gre='\e[42m';    On_IGre='\e[0;102m';
Yel='\e[0;33m';     BYel='\e[1;33m';    UYel='\e[4;33m';    IYel='\e[0;93m';    BIYel='\e[1;93m';   On_Yel='\e[43m';    On_IYel='\e[0;103m';
Blu='\e[0;34m';     BBlu='\e[1;34m';    UBlu='\e[4;34m';    IBlu='\e[0;94m';    BIBlu='\e[1;94m';   On_Blu='\e[44m';    On_IBlu='\e[0;104m';
Pur='\e[0;35m';     BPur='\e[1;35m';    UPur='\e[4;35m';    IPur='\e[0;95m';    BIPur='\e[1;95m';   On_Pur='\e[45m';    On_IPur='\e[0;105m';
Cya='\e[0;36m';     BCya='\e[1;36m';    UCya='\e[4;36m';    ICya='\e[0;96m';    BICya='\e[1;96m';   On_Cya='\e[46m';    On_ICya='\e[0;106m';
Whi='\e[0;37m';     BWhi='\e[1;37m';    UWhi='\e[4;37m';    IWhi='\e[0;97m';    BIWhi='\e[1;97m';   On_Whi='\e[47m';    On_IWhi='\e[0;107m';

# Example:
# say "hello world" info
# say "hello world" warn 1
say() {
    INDT=${3:-0}
    SHINDT=""

    if [ $INDT -gt 0 ]; then
        for i in $(seq 1 $INDT); do
            SHINDT="$SHINDT    "
        done
    fi
    
    export Yel; export Gre; export Whi; export Red;

    if [ -n "$2" ]; then
        COLOR=$Whi
        case $2 in
            "error") COLOR="$Red";;
            "warn") COLOR="$Yel";;
            "info") COLOR="$Gre";;
        esac
        echo -ne "${COLOR}$SHINDT$1$RCol"
    else
        echo -ne "$SHINDT$1"
    fi
}

sayln() {
    say "$1" ${2:-""} ${3:-0}
    echo ""
}

sayDone() {
    sayln " [Done]" info
}

sayFailed() {
    sayln " [Failed]" error
}

heading() {
    FIL=''
    for i in $(seq 0 ${#1}); do
        FIL="$FIL-" 
    done 
    sayln "-------$FIL-------"
    sayln "|       $1      |"
    sayln "-------$FIL-------" 
}

heading "Running the CIS configurations"

export WORKDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
if [ -f "$WORKDIR/envs/settings.$ENVIR" ]; then
    say "** - Loading \"$ENVIR\" environment variables..."
    export $(echo $(cat $WORKDIR/envs/settings.$ENVIR | sed 's/#.*//g'| xargs) | envsubst)
    sayDone
fi

export FORWARD
export RECV_SYSLOG
export UPGRADE
export KEEP_FIREWALL
export -f say
export -f sayln
export -f sayDone
export -f sayFailed
CNT=0
ERRS=0
for config in $(dirname "$0")/configurations/*; do
    CNT=$((cnt+=1))
    sayln "$cnt. Running $(say \"$(basename $config)\" info) file..."
    bash $config

    if [ $? -gt 0 ]; then
        ERRS=$((errs + 1))
    fi
done

