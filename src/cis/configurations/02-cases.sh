#!/bin/bash
#
# Modified Date: Tuesday, June 6th 2022
# Author: Kuan Cheang
# Version: 1.0
#
# © Copyright 2021, Asian Software Quality Institute Limited (ASQI)
#
# This document, which contains confidential material, is private and confidential
# and is the property and copyright of ASQI. No part of this document may be reproduced,
# stored in a retrieval system or transmitted in any form or by any means, electronic,
# mechanical, chemical, photocopy, recording or otherwise without the prior written
# permission of ASQI. Upon completion of the Archive The Logs In the Syslog Server for SJM Resorts, S.A.,
# the copyright of this document will be transferred to SJM Resorts, S.A.



say "- 2.1.7 Ensure NFS service is not installed" "" 1

    apt-get purge nfs-kernel-server -y > /dev/null 2>&1 

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 2.1.1.1~2.1.1.2 Ensure time synchronization is in use (Automated)" "" 1
    
    apt-get purge -y ntp chrony > /dev/null

    tar -zxf $WORKDIR/packages/systemd-timesyncd-all.tar.gz -C /var/cache/apt/archives/
    apt-get -q install -y systemd-timesyncd > /dev/null 2>&1

    sed  -e "s/^#\?\(NTP\)=.*/\1=$REMOTE_NTP_SERVER/g" \
        -e "s/^#\?\(FallbackNTP\)=.*/\1=${REMOTE_FALLBACK_NTP_SERVER:-ntp.ubuntu.com}/g" \
        -e "s/^#\?\(RootDistanceMaxSec\)=.*/\1=5/g" \
        -i /etc/systemd/timesyncd.conf > /dev/null
   
    systemctl restart systemd-timesyncd 1> /dev/null
    timedatectl set-ntp true 1> /dev/null
     
    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 2.1.16 Ensure rsync service is not installed" "" 1

    apt-get purge rsync -y > /dev/null 2>&1 

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 2.2.4 Ensure telnet service is not installed" "" 1

    apt-get purge telnet -y > /dev/null 2>&1 

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 2.2.6 Ensure RPC service is not installed" "" 1

    apt-get purge rpcbind -y > /dev/null 2>&1 
    apt-get autoremove -y > /dev/null 2>&1

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

exit 0
