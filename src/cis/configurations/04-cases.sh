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

say "- 4.2.1.3 Ensure logging is configured (Manual)" "" 1

    cat <<EOF | tee /etc/rsyslog.d/50-default.conf > /dev/null
#  Default rules for rsyslog.
#
#			For more information see rsyslog.conf(5) and /etc/rsyslog.conf

#
# Emergencies are sent to everybody logged in.
#

*.emerg				        :omusrmsg:*

#
# First some standard log files.  Log by facility.
#

auth,authpriv.*			     /var/log/auth.log
*.*;auth,authpriv.none		-/var/log/syslog
cron.*				         /var/log/cron.log
#daemon.*			        -/var/log/daemon.log
kern.*				        -/var/log/kern.log
#lpr.*				        -/var/log/lpr.log
mail.*				        -/var/log/mail.log
user.*				        -/var/log/user.log
news.crit			        -/var/log/news/news.crit
news.err			        -/var/log/news/news.err
news.notice			        -/var/log/news/news.notice

#
# Logging for the mail system.  Split it up so that
# it is easy to write scripts to parse these files.
#


mail.*			            -/var/log/mail
mail.info			        -/var/log/mail.info
mail.warning			    -/var/log/mail.warn
mail.err			         /var/log/mail.err

#
# Some "catch-all" log files.
#
#*.=debug;\
#	auth,authpriv.none;\
#	news.none;mail.none	-/var/log/debug

*.=warning;*.=err           -/var/log/warn
*.crit                       /var/log/warn

*.*;mail.none;news.none		-/var/log/messages
local0,local1.*			    -/var/log/localmessages
local2,local3.*			    -/var/log/localmessages
local4,local5.*			    -/var/log/localmessages
local6,local7.*			    -/var/log/localmessages

#
# I like to have messages displayed on the console, but only on a virtual
# console I usually leave idle.
#
#daemon,mail.*;\
#	news.=crit;news.=err;news.=notice;\
#	*.=debug;*.=info;\
#	*.=notice;*.=warn	/dev/tty8
EOF

    systemctl restart rsyslog > /dev/null

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 4.2.1.4 Ensure rsyslog default file permissions configured (Automated)" "" 1

    chmod 640 /etc/rsyslog.conf
    chmod 640 /etc/rsyslog.d/*.conf

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 4.2.1.5 Ensure rsyslog is configured to send logs to a remote log host (Automated) (forwarding enable only)" "" 1

    tcpset=$(grep -E '^\s*([^#]+\s+)?action\(([^#]+\s+)?\btarget=\"?[^#"]+\"?\b' /etc/rsyslog.conf /etc/rsyslog.d/*.conf)

    # clear the old syntax of forwarding logs
    sed -e 's/^\s*\*\.\*\s*@\?.*//g' -i /etc/rsyslog.conf > /dev/null
    
    if [ "$FORWARD" = "enable" ]; then
        
        if [ -z "$tcpset" ]; then
            cat <<EOF | tee /etc/rsyslog.d/99-forward.conf > /dev/null
if (\$fromhost-ip == "127.0.0.1") then {
    *.* action(type="omfwd" target="$REMOTE_SYSLOG_SERVER" port="514" protocol="tcp" 
               action.resumeRetryCount="100" queue.type="LinkedList" queue.size="1000")
}
EOF
            chmod 640 /etc/rsyslog.d/99-forward.conf
            systemctl restart rsyslog > /dev/null
        fi
    else 
        [ -f /etc/rsyslog.d/99-forward.conf ] && rm -rf /etc/rsyslog.d/99-forward.conf > /dev/null 
    fi

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 4.2.1.6 Ensure remote rsyslog messages are only accepted on designated log hosts (only log server enabled) " "" 1

    # Comment the default module enabling methods
    sed -e 's/^#\?\(module(load="\(imtcp\|imudp\)")\)/#\1/g' -i /etc/rsyslog.conf > /dev/null
    sed -e 's/^#\?\(input(type="\(imtcp\|imudp\)" port=".*")\)/#\1/g' -i /etc/rsyslog.conf > /dev/null
    sed -e 's/^\(\$DirCreateMode\) .*/\1 0750/g' -i /etc/rsyslog.conf > /dev/null
    sed -e 's/^\(\$Umask\) .*/\1 0027/g' -i /etc/rsyslog.conf > /dev/null

    if [ "$RECV_SYSLOG" = "enable" ]; then
        # These settings will enable the resyslog server to receive tcp syslog message by 514 port
        test -z "$(grep '^\s*\$ModLoad imtcp' /etc/rsyslog.conf)" && \
            echo '$ModLoad imtcp' | tee -a /etc/rsyslog.conf > /dev/null
        test -z "$(grep '^\s*\$InputTCPServerRun.*' /etc/rsyslog.conf)" && \
            echo '$InputTCPServerRun 514' | tee -a /etc/rsyslog.conf > /dev/null

        test -z "$(grep '^\s*\$ModLoad imudp' /etc/rsyslog.conf)" && \
            echo '$ModLoad imudp' | tee -a /etc/rsyslog.conf > /dev/null
        test -z "$(grep '^\s*\$UDPServerRun.*' /etc/rsyslog.conf)" && \
            echo '$UDPServerRun 514' | tee -a /etc/rsyslog.conf > /dev/null
    fi

    systemctl restart rsyslog > /dev/null
    
    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi
    
say "- 4.2.2.1 Ensure journald is configured to send logs to rsyslog" "" 1

    sed -e 's/#\?\(ForwardToSyslog=yes\)/\1/g' -i /etc/systemd/journald.conf > /dev/null

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 4.2.2.2 Ensure journald is configured to compress large log files (Automated)" "" 1

    sed -e 's/#\?\(Compress=yes\)/\1/g' -i /etc/systemd/journald.conf > /dev/null

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 4.2.2.3 Ensure journald is configured to write logfiles to persistent disk" "" 1

    sed -e 's/#\?\(Storage\)=auto/\1=persistent/g' -i /etc/systemd/journald.conf > /dev/null
    systemctl restart systemd-journald.service > /dev/null

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 4.2.3 Ensure permissions on all logfiles are configured (Automated)" "" 1
    
    find /var/log -type f -exec chmod g-wx,o-rwx '{}' + -o -type d -exec chmod g-w,o-rwx '{}' +;

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 4.3 Ensure logrotate is configured (Manual)" "" 1
    
    cat <<EOF | tee /etc/logrotate.d/rsyslog > /dev/null     
/var/log/syslog
{
    rotate 7
    daily
    missingok
    notifempty
    delaycompress
    compress
    create 0640 syslog adm
    maxage 30
    postrotate
        /usr/lib/rsyslog/rsyslog-rotate
    endscript
}

/var/log/mail.info
/var/log/mail.warn 
/var/log/mail.err
/var/log/mail.log
/var/log/daemon.log
/var/log/kern.log
/var/log/auth.log
/var/log/user.log
/var/log/lpr.log
/var/log/cron.log
/var/log/debug
/var/log/messages
/var/log/warn
/var/log/localmessages
{
    rotate 4
    weekly
    missingok
    notifempty
    compress
    delaycompress
    sharedscripts
    create 0640 syslog adm
    maxage 30
    postrotate
        /usr/lib/rsyslog/rsyslog-rotate
    endscript
}
EOF
    
    logrotate -f /etc/logrotate.d/* > /dev/null
    
    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi


say "- 4.4 Ensure logrotate assigns appropriate permissions (Automated)" "" 1

    sed -e 's/^\(\s*create\).*$/\1 0640 root root/g' -i /etc/logrotate.conf > /dev/null
    find /etc/logrotate.d -type f -exec sed -e 's/^\(\s*create\).*$/\1 0640 root root/g' -i {} +;
    sed -e 's/^\(.*\(wtmp\|btmp\|lastlog\)\).*/\1 0640 root utmp -/g' -i /usr/lib/tmpfiles.d/var.conf

    if [ -z "$(grep -E "^maxage.*$" /etc/logrotate.conf)" ]; then
        echo "maxage 30" >> /etc/logrotate.conf
    fi

    systemctl restart logrotate.service
      
    # Ensure the newly rotate file is generated at specified owner and permission 
    logrotate -f /etc/logrotate.d/* > /dev/null

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

exit 0
