#!/bin/bash

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
        systemctl enable aidecheck.service > /dev/null
        systemctl --now enable aidecheck.timer > /dev/null
    fi

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 6.1.11~6.1.12 Ensure no unowned/ungrouped files or directories exist (Automated)" "" 1

    chown -R root:root /var/cache/apt/archives/*
    chown -R root:root /var/cache/private/*
    chmod -R 640 /var/cache/apt/archives/*
    chmod -R 640 /var/cache/private/*
    
    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

exit 0
