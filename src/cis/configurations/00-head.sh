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

say "- Change the default shell using Bash instead of Zsh" "" 1
    chsh -s /bin/bash root 
    chsh -s /bin/bash sysadmin
    
    test -z "$(grep -E '^EDITOR=.*$' /root/.bashrc)" && \
        echo -e "\nEDITOR=/usr/bin/vim" | tee -a /root/.bashrc > /dev/null
    test -z "$(grep -E '^EDITOR=.*$' /home/sysadmin/.bashrc)" && \
        echo -e "\nEDITOR=/usr/bin/vim" | tee -a /home/sysadmin/.bashrc > /dev/null

    sayDone

say "- Change the locale to en_US.UTF-8" "" 1

    sed -i /etc/locale.gen -e 's/^#\?\s*\(en_US\.UTF-8 UTF-8\)\s*/\1/g' > /dev/null 2>&1
    locale-gen > /dev/null 2>&1
    sayDone

say "- Fixing the rsyslog upgraded breaking changes" "" 1

    sed -e 's/^$PrivDropTo\(User\|Group\).*/#\0/g' -i /etc/rsyslog.conf
    
    sayDone

say "- Create a bash_aliases file to show the current hostname" "" 1

    awk -F: '($1!~/(halt|sync|shutdown)/ && $7!~/^(\/usr)?\/sbin\/nologin(\/)?$/ && $7!~/(\/usr)?\/bin\/false(\/)?$/) { print $1 " " $6 }' /etc/passwd | \
        while read -r user dir; do 
            if [ -f /usr/bin/figlet -a -f /usr/games/lolcat ]; then
                cat <<EOF | tee $dir/.bash_aliases > /dev/null
/usr/bin/figlet \$(hostname) | /usr/games/lolcat
EOF
            else 
                echo "" | tee $dir/.bash_aliases > /dev/null
            fi
            chmod 644 $dir/.bash_aliases
        done

    sayDone

say "- Remove unnecessary packages." "" 1
    FRONTEND=noninteractive apt-get -q purge -y \
        clamav-freshclam \
        clamav-daemon \
        clamav \
        sendmail \
        sendmail-bin \
        snapd > /dev/null
    apt-get autoremove -y > /dev/null
    rm -rf /snap > /dev/null
    rm -rf /var/cache/snapd/ > /dev/null
    rm -rf /etc/logrotate.d/clamav* > /dev/null
    rm -rf /etc/clamav* > /dev/null
    rm -rf /var/log/clamav* > /dev/null
    rm -rf /root/snap > /dev/null
    rm -rf /var/lib/sendmail > /dev/null
    rm -rf /etc/cron.d/sendmail > /dev/null

    if [ "$(cat /etc/environment | grep 'snap/bin')" ]; then
        sed -e 's/:\?\/snap\/bin//g' -i /etc/environment
    fi
    
    sed -e 's/:\?\/snap\/bin//g' -i /etc/sudoers

    systemctl restart logrotate
    sayDone

say "- Remove user's unnecessary files" "" 1
    awk -F: '($1!~/(halt|sync|shutdown)/ && $7!~/^(\/usr)?\/sbin\/nologin(\/)?$/ && $7!~/(\/usr)?\/bin\/false(\/)?$/) { print $1 " " $6 }' /etc/passwd | \
        while read -r user dir; do 
            if [ -d $dir/.fzf ]; then
                rm -rf $dir/.fzf
            fi
        done

    sayDone

#say "- Permit root login via SSH." "" 1
#    sed -e "s/^#\?\(PermitRootLogin\) .\+$/\1 yes/g" -i /etc/ssh/sshd_config 
#    systemctl restart sshd > /dev/null
#    sayDone

say "- Creating a symbolic commands for Tenable to audit the configuration in /usr/bin/" "" 1
    [ ! -f /usr/bin/grep ] && ln -s /bin/grep /usr/bin/grep
    [ ! -f /usr/bin/sed ] && ln -s /bin/sed /usr/bin/sed
    sayDone

say "- Ensure DNS resolver is set" "" 1
    sed -e "s/^#\?\(DNS\)=.*/\1=$REMOTE_DNS_SERVER/g" \
        -e "s/^#\?\(FallbackDNS\)=.*/\1=$REMOTE_FALLBACK_DNS_SERVER/g" \
        -e "s/^#\?\(Domains\)=.*/\1=$REMOTE_DNS_DOMAIN/g" \
        -i /etc/systemd/resolved.conf
    systemctl restart systemd-resolved
    sayDone
exit 0
