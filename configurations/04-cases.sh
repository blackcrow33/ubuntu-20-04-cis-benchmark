#!/bin/bash

say "- 4.2.1.3 Ensure logging is configured (Manual)" "" 1

    cat <<EOF | tee /etc/rsyslog.d/50-default.conf > /dev/null
*.emerg                      :omusrmsg:*
auth,authpriv.*              /var/log/auth.log
mail.*                      -/var/log/mail
mail.info                   -/var/log/mail.info
mail.warning                -/var/log/mail.warn
mail.err                     /var/log/mail.err
news.crit                   -/var/log/news/news.crit
news.err                    -/var/log/news/news.err
news.notice                 -/var/log/news/news.notice
*.=warning;*.=err           -/var/log/warn
*.crit                       /var/log/warn
*.*;mail.none;news.none     -/var/log/messages
local0,local1.*             -/var/log/localmessages
local2,local3.*             -/var/log/localmessages
local4,local5.*             -/var/log/localmessages
local6,local7.*             -/var/log/localmessages
EOF

    systemctl restart rsyslog > /dev/null

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 4.2.1.4 Ensure rsyslog default file permissions configured (Automated)" "" 1

    chmod 640 /etc/rsyslog.conf
    chmod 640 /etc/rsyslog.d/*.conf

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 4.2.1.5 Ensure rsyslog is configured to send logs to a remote log host (Automated)" "" 1

    tcpset=$(grep -E '^\s*([^#]+\s+)?action\(([^#]+\s+)?\btarget=\"?[^#"]+\"?\b' /etc/rsyslog.conf /etc/rsyslog.d/*.conf)
    oldset=$(grep -E '^[^#]\s*\S+\.\*\s+@' /etc/rsyslog.conf /etc/rsyslog.d/*.conf)

    test -z "$REMOTE_SYSLOG_IP" && sayFailed || (
        if [ -z "$tcpset" -a -z "$oldset" ]; then
            cat <<EOF | tee /etc/rsyslog.d/99-forward.conf > /dev/null
if (\$fromhost-ip == "127.0.0.1") then {
    *.* action(type="omfwd" target="$REMOTE_SYSLOG_IP" port="514" protocol="tcp" 
               action.resumeRetryCount="100" queue.type="LinkedList" queue.size="1000")
}
EOF
            chmod 640 /etc/rsyslog.d/99-forward.conf
            systemctl restart rsyslog > /dev/null
        fi

        if [ $? -eq 0 ]; then sayDone; else sayFailed; fi
    )
    
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

say "- 4.4 Ensure logrotate assigns appropriate permissions (Automated)" "" 1

    sed -e 's/^\(\s*create\).*$/\1 0640 root utmp/g' -i /etc/logrotate.conf > /dev/null
    find /etc/logrotate.d -type f -exec sed -e 's/^\(\s*create\).*$/\1 0640 root utmp/g' -i {} +;
    sed -e 's/^\(.*\(wtmp\|btmp\|lastlog\)\).*/\1 0640 root utmp -/g' -i /usr/lib/tmpfiles.d/var.conf

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

exit 0
