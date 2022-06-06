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
        echo -e "\nEDITOR=/usr/bin/vim" | tee -a /root/.bashrc
    test -z "$(grep -E '^EDITOR=.*$' /home/sysadmin/.bashrc)" && \
        echo -e "\nEDITOR=/usr/bin/vim" | tee -a /home/sysadmin/.bashrc

    sayDone

say "- Remove unnecessary packages." "" 1
    apt-get purge clamav-freshclam clamav-daemon clamav > /dev/null
    apt-get autoremove > /dev/null
    rm -rf /etc/logrotate.d/clamav*
    rm -rf /etc/clamav*
    rm -rf /var/log/clamav*
    systemctl restart logrotate
    sayDone
say "- Permit root login via SSH." "" 1
    sed -e "s/^#\?\(PermitRootLogin\) .\+$/\1 yes/g" -i /etc/ssh/sshd_config 
    systemctl restart sshd > /dev/null
    sayDone
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
