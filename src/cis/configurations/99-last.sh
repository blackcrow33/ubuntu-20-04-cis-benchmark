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

say "- Replacing the apt source list" "" 1
    cat <<EOF | sudo tee -a /etc/apt/sources.list > /dev/null
# See http://help.ubuntu.com/community/UpgradeNotes for how to upgrade to
# newer versions of the distribution.
deb http://mo.archive.ubuntu.com/ubuntu focal main restricted

## Major bug fix updates produced after the final release of the
## distribution.
deb http://mo.archive.ubuntu.com/ubuntu focal-updates main restricted

## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
## team. Also, please note that software in universe WILL NOT receive any
## review or updates from the Ubuntu security team.
deb http://mo.archive.ubuntu.com/ubuntu focal universe
deb http://mo.archive.ubuntu.com/ubuntu focal-updates universe

## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
## team, and may not be under a free licence. Please satisfy yourself as to
## your rights to use the software. Also, please note that software in
## multiverse WILL NOT receive any review or updates from the Ubuntu
## security team.
deb http://mo.archive.ubuntu.com/ubuntu focal multiverse
deb http://mo.archive.ubuntu.com/ubuntu focal-updates multiverse

## N.B. software from this repository may not have been tested as
## extensively as that contained in the main release, although it includes
## newer versions of some applications which may provide useful features.
## Also, please note that software in backports WILL NOT receive any review
## or updates from the Ubuntu security team.
deb http://mo.archive.ubuntu.com/ubuntu focal-backports main restricted universe multiverse

## Uncomment the following two lines to add software from Canonical's
## 'partner' repository.
## This software is not part of Ubuntu, but is offered by Canonical and the
## respective vendors as a service to Ubuntu users.
# deb http://archive.canonical.com/ubuntu bionic partner
# deb-src http://archive.canonical.com/ubuntu bionic partner

deb http://mo.archive.ubuntu.com/ubuntu focal-security main restricted
deb http://mo.archive.ubuntu.com/ubuntu focal-security universe
deb http://mo.archive.ubuntu.com/ubuntu focal-security multiverse
EOF
    
    rm -rf /etc/apt/sources.list.d/* > /dev/null

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi


say "- 1.3.1 Ensure aide are installed" "" 1
    tar -zxf "$WORKDIR/packages/aide-all.tar.gz" -C /var/cache/apt/archives/
    DEBIAN_FRONTEND=noninteractive apt-get -q install -y aide aide-common > /dev/null 2>&1
    # NOTE: Uncomment the following lines to run the initialization of aide
    # aideinit
    # mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 1.3.2 Ensure filesystem integrity is regularly checked (Automated)" "" 1
    if [ $(systemctl is-enabled aidecheck.service 2>&1 | grep "Failed" | wc -l) -gt 0 ]; then
        cat <<EOF | tee /etc/systemd/system/aidecheck.service > /dev/null
[Unit]
Description=Aide Check

[Service]
Type=simple
ExecStart=/usr/bin/aide.wrapper --config /etc/aide/aide.conf --check

[Install]
WantedBy=multi-user.target
EOF

        cat <<EOF | tee /etc/systemd/system/aidecheck.timer > /dev/null
[Unit]
Description=Aide check every day at 5AM

[Timer]
OnCalendar=*-*-* 05:00:00
Unit=aidecheck.service

[Install]
WantedBy=multi-user.target
EOF

        chown root:root /etc/systemd/system/aidecheck.*        
        chmod 0644 /etc/systemd/system/aidecheck.*
        systemctl daemon-reload > /dev/null
        systemctl enable aidecheck.service > /dev/null 2>&1
        systemctl --now enable aidecheck.timer > /dev/null 2>&1
    fi

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- Syncing the latest apt package information" "" 1
    
    if [ "$UPGRADE" = "enable" ]; then
        apt-offline install $WORKDIR/packages/apt-offline-2022-06-10.zip > /dev/null
        find /var/cache/apt/archives/ -type f -exec chmod 640 {} +;

        mount -o remount,rw,nosuid,nodev,relatime /tmp

        DEBIAN_FRONTEND=noninteractive apt-get -q upgrade -y > /dev/null 2>&1
    fi
    
    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi



say "- 6.1.11~6.1.12 Ensure no unowned/ungrouped files or directories exist (Automated)" "" 1

    chown -R root:root /var/cache/apt/archives/*
    
    find /var/cache/apt/archives/ -type f -exec chmod 640 {} +;
    [ -d /var/cache/private ] && chown -R root:root /var/cache/private/ && \
        chmod -R 750 /var/cache/private/
    
    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 1.1.2 Ensure /tmp is configured" "" 1
    ARG="tmpfs /tmp tmpfs defaults,rw,nosuid,nodev,noexec,relatime 0 0"
    if [ $(cat /etc/fstab | grep -E "^tmpfs.+$" | wc -l) -eq 0 ]; then
        echo $ARG | tee -a /etc/fstab > /dev/null
        mount -a 2> /dev/null
    fi

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 1.1.9 Ensure noexec option set on /dev/shm partition" "" 1
    if [ $(findmnt -n /dev/shm | grep -v noexec | wc -l) -ne 0 ]; then
        if [ $(cat /etc/fstab | grep /dev/shm | wc -l) -eq 0 ]; then
            echo "tmpfs /dev/shm tmpfs defaults,nodev,nosuid,noexec 0 0" | tee -a /etc/fstab > /dev/null
            mount -a 2> /dev/null
        fi
        mount -o remount,nosuid,nodev,noexec /dev/shm
    fi
    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi



say "- Cleaning up the scripts and packages for the CIS configuration." "" 1
    rm -rf $WORKDIR > /dev/null

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi


exit 0
