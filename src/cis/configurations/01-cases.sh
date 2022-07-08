#!/bin/bash
#
# Modified Date: Tuesday, March 8th 2022, 6:07:15 pm
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

say "- 1.1.1.x Ensure mounting of cramfs, freevxfs, jffs2, hfs, hfsplus, udf, usb-storage filesystems is disabled - modprobe" "" 1
    MODS=(cramfs freevxfs jffs2 hfs hfsplus udf usb-storage)
    for mod in ${MODS[@]}; do
        echo "install $mod /bin/true" | tee /etc/modprobe.d/$mod.conf > /dev/null
        rmmod $mod > /dev/null 2>&1
    done

    sayDone

say "- 1.4.1 Ensure permissions on bootloader config are not overridden (Automated)" "" 1
    
    if [ $(cat /usr/sbin/grub-mkconfig | grep "chmod 444" | wc -l) -gt 0 ]; then
        sed -ri 's/chmod\s+[0-7][0-7][0-7]\s+\$\{grub_cfg\}\.new/chmod 400 ${grub_cfg}.new/' /usr/sbin/grub-mkconfig
        sed -ri 's/ && ! grep "\^password" \$\{grub_cfg\}.new >\/dev\/null//' /usr/sbin/grub-mkconfig
    fi
    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 1.4.2 Ensure bootloader password is set (Automated)" "" 1
    
    if [ $(grep "^set superusers" /boot/grub/grub.cfg | wc -l) -eq 0 -a  $(grep "^password" /boot/grub/grub.cfg | wc -l) -eq 0 ]; then
        echo -e "cat<<EOF\nset superusers=\"sysadmin\"\npassword_pbkdf2 sysadmin $BOOT_PASSWORD\nEOF" | tee /etc/grub.d/42_custom >> /dev/null
        chmod 755 /etc/grub.d/42_custom
        sed -e 's/^CLASS=".*"$/CLASS="--class gnu-linux --class gnu --class os --unrestricted"/' -i /etc/grub.d/10_linux 
        update-grub > /dev/null 2>&1
    fi

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 1.5.2 Ensure address space layout randomization (Automated)"

    if [ -z $(sysctl kernel.randomize_va_space | grep -E "^kernel\.randomize_va_space\s*=\s*2") ]; then
        if [ -z $(grep -E "^kernel\.randomize_va_space\s*=.*" /etc/sysctl.d/99-sysctl.conf) ]; then
            echo "kernel.randomize_va_space = 2" | tee -a /etc/sysctl.d/99-sysctl.conf > /dev/null
        else 
            sed -e 's/^#\?\(kernel\.randomize_va_space\)\s*=.*/\1 = 2/g' -i /etc/sysctl.d/99-sysctl.conf
        fi

        sysctl -w kernel.randomize_va_space=2
    fi
    
    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 1.5.4 Ensure core dumps are restricted (Automated)" "" 1

    echo "* hard core 0" | tee /etc/security/limits.d/00_custom > /dev/null

    if [ $(cat /etc/sysctl.d/99-sysctl.conf | grep "fs.suid_dumpable=0" | wc -l) -eq 0 ]; then
        echo "fs.suid_dumpable=0" | tee -a /etc/sysctl.d/99-sysctl.conf > /dev/null
        sysctl -w fs.suid_dumpable=0 > /dev/null
        sysctl -p > /dev/null
    fi
       
    if [ "$(systemctl is-enabled apport 2> /dev/null)" = "enabled" ]; then
        # apport has to stop for disabling the core dump 
        systemctl stop apport > /dev/null 2>&1
        systemctl disable apport > /dev/null 2>&1
    fi

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 1.7.1 Ensure message of the day is configured properly (Automated)" "" 1
    
    cat <<EOF | tee /etc/motd > /dev/null

All activities performed on this system will be monitored.

This OS is configured and specialized for the ELK related services.
You must have explicit, authorized permission to access or configure this system. 
Unauthorized attempts and actions to access or use this system may result in civil and/or criminal penalties. 

EOF
    
    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 1.7.2~1.7.3 Ensure local/remote login warning banner is configured properly" "" 1

    msg="Authorized uses only. All activities performed on this system will be monitored."
    echo $msg > /etc/issue
    echo $msg > /etc/issue.net

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 1.7.4~1.7.6 Ensure permissions on /etc/{motd,issue,issue.net} are configured (Automated)" "" 1
    
    paths=(
        /etc/motd 
        /etc/issue 
        /etc/issue.net
    )

    for p in "${paths[@]}"; do
        chown root:root $(readlink -e $p)
        chmod u-x,go-wx $(readlink -e $p)
    done
     
    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

exit 0
