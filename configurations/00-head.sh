#!/bin/bash
say "- change the default shell using bash instead of zsh" "" 1
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
say "- Creating a symbolic commands for Tenable to audit the configuration in /usr/bin/"
    [ ! -f /usr/bin/grep ] && ln -s /bin/grep /usr/bin/grep
    [ ! -f /usr/bin/sed ] && ln -s /bin/sed /usr/bin/sed
    sayDone
exit 0
