#!/bin/bash

say "- 5.1.2~5.1.7 Ensure permissions on crontab are configured (Automated)" "" 1
    chown root:root /etc/cron{tab,.hourly,.daily,.weekly,.monthly,.d}
    chmod og-rwx /etc/cron{tab,.hourly,.daily,.weekly,.monthly,.d}

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 5.1.8 Ensure cron is restricted to authorized users (Automated)" "" 1
    test -f /etc/cron.deny && rm /etc/cron.deny
    touch /etc/cron.allow
    chown root:root /etc/cron.allow
    chmod og-rwx /etc/cron.allow

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 5.1.9 Ensure at is restricted to authorized users (Automated)" "" 1
    test -f /etc/at.deny && rm /etc/at.deny
    touch /etc/at.allow
    chown root:root /etc/at.allow
    chmod og-rwx /etc/at.allow

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 5.2.2~5.2.3 Ensure sudo commands use pty and log file exists (Automated)" "" 1
    cat <<EOF | tee /etc/sudoers.d/defaults > /dev/null
Defaults use_pty
Defaults logfile="/var/log/sudo.log"
EOF
    
    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 5.3.1 Ensure permissions on /etc/ssh/sshd_config are configured (Automated)" "" 1
    chown root:root /etc/ssh/sshd_config
    chmod og-rwx /etc/ssh/sshd_config

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 5.3.4 Ensure SSH access is limited (Automated)" "" 1
    
    if [ -z "$(cat /etc/ssh/sshd_config | grep -Ei '^\s*([Aa]llow|[Dd]eny)([Uu]sers|[Gg]roups)\s+\S+')" ]; then
        echo "AllowUsers sysadmin root" | tee -a /etc/ssh/sshd_config > /dev/null
    fi


    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 5.3.x Ensure SSH settings is appropriate (Automated)" "" 1
    
    sed -e 's/^\s*#\(LogLevel\|IgnoreRhosts\|HostbasedAuthentication\|MaxSessions\|MaxStartups.*\)/\1/g' -i /etc/ssh/sshd_config  
    sed -e 's/^\s*#\(PermitEmptyPasswords\|PermitUserEnvironment.*\)/\1/g' -i /etc/ssh/sshd_config  
    sed -e 's/^\s*#\(MaxAuthTries\).*/\1 4/g' -i /etc/ssh/sshd_config  
    sed -e 's/^\s*#\(LoginGraceTime\).*/\1 1m/g' -i /etc/ssh/sshd_config  
    sed -e 's/^\s*#\(ClientAliveInterval\).*/\1 300/g' -i /etc/ssh/sshd_config  
    sed -e 's/^\s*#\(ClientAliveCountMax\).*/\1 3/g' -i /etc/ssh/sshd_config  
    sed -e 's/^\s*#\(Banner\).*/\1 \/etc\/issue\.net/g' -i /etc/ssh/sshd_config  
    
    if [ -z "$(grep -E "^\s*Ciphers\s.*$" /etc/ssh/sshd_config)" ]; then
        echo "Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr"\
            | tee -a /etc/ssh/sshd_config > /dev/null
    fi

    if [ -z "$(grep -E "^\s*Macs\s.*$" /etc/ssh/sshd_config)" ]; then
        echo "MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256" \
            | tee -a /etc/ssh/sshd_config > /dev/null
    fi

    if [ -z "$(grep -E "^\s*KexAlgorithms\s.*$" /etc/ssh/sshd_config)" ]; then
        echo "KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group14-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256" \
            | tee -a /etc/ssh/sshd_config > /dev/null
    fi

    systemctl restart sshd

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 5.4.1 Ensure password creation requirements are configured (Automated)" "" 1
    
    tar -zxvf $WORKDIR/packages/libpam-pwquality-all.tar.gz -C /var/cache/apt/archives/ > /dev/null
    DEBIAN_FRONTEND=noninteractive apt-get -q install -y libpam-pwquality 1> /dev/null
    
    sed -e 's/^#\?\s*\(minlen\s=\)\s*\S*/\1 14/g' -i /etc/security/pwquality.conf
    sed -e 's/^#\?\s*\(minclass\s=\)\s*\S*/\1 4/g' -i /etc/security/pwquality.conf
    sed -e 's/^#\?\s*\(\(dcredit\|ucredit\|ocredit\|lcredit\)\s=\).*/\1 -1/g' -i /etc/security/pwquality.conf

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi


say "- 5.4.2 Ensure lockout for failed password attempts is configured" "" 1
    
    if [ -z "$(grep 'pam_tally2' /etc/pam.d/common-auth)" ]; then
        echo "auth required pam_tally2.so onerr=fail audit silent deny=5 unlock_time=900" | \
            tee -a /etc/pam.d/common-auth > /dev/null
    fi

    if [ $(grep -E "pam_(tally2|deny)\.so" /etc/pam.d/common-account | wc -l) -ne 2 ]; then
        sed -e 's/^\(account\s\+requisite\s\+pam_deny.so\)/\1\naccount required\t\t\tpam_tally2.so/g' \
            -i /etc/pam.d/common-account
    fi

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi
 
say "- 5.4.3 Ensure password reuse is limited (Automated)" "" 1

    if [ -z "$(cat /etc/pam.d/common-password | grep pam_pwhistory.so)" ]; then
        sed -e 's/^\(password\s\+requisite\s\+pam_pwquality.so.*\)/\1\npassword\trequired\t\t\tpam_pwhistory.so remember=5/g' \
            -i /etc/pam.d/common-password
    fi

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 5.5.1.1 Ensure minimum days between password changes is configured (Automated)" "" 1
    
    sed -e 's/^\(PASS_MIN_DAYS\)\s\+\S*/\1 1/g' -i /etc/login.defs
    
    for user in $(awk -F : '(/^[^:]+:[^!*]/ && $4 < 1){print $1 " " $4}' /etc/shadow | cut -d" " -f1); do
        chage --mindays 1 $user
    done

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 5.5.1.2 Ensure password expiration is 365 days or less (Automated)" "" 1
    
    sed -e 's/^\(PASS_MAX_DAYS\)\s\+\S*/\1 365/g' -i /etc/login.defs
    
    for user in $(awk -F: '(/^[^:]+:[^!*]/ && ($5>365 || $5~/([0-1]|-1|\s*)/)){print $1 " " $5}' /etc/shadow | cut -d" " -f1); do
        chage --maxdays 365 $user
    done

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 5.5.1.4 Ensure inactive password lock is 30 days or less (Automated)" "" 1
    
    useradd -D -f 30

    for user in $(awk -F: '(/^[^:]+:[^!*]/ && ($7~/(\s*|-1)/ || $7>30)){print $1 " " $7}' /etc/shadow | cut -d" " -f1); do
        chage --inactive 30 $user
    done
    
    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 5.5.4 Ensure default user umask is 027 or more restrictive (Automated)" "" 1

    sed -e 's/^\(UMASK\s\+\).*/\1 027/g' -i /etc/login.defs
    
    echo "umask 027" | tee /etc/profile.d/custom.sh > /dev/null
    
    awk -F: '($1!~/(halt|sync|shutdown)/ && $7!~/^(\/usr)?\/sbin\/nologin(\/)?$/ && $7!~/(\/usr)?\/bin\/false(\/)?$/) { print $1 " " $6 }' \
        /etc/passwd | while read -r user dir; do
            if [ -z "$(grep -e '^umask .*$' $dir/.bashrc)" ]; then
                tee -a $dir/.bashrc > /dev/null
            fi
        done


    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 5.5.5 Ensure default user shell timeout is 900 seconds or less (Automated)" "" 1
    
    if test -z "$(cat /etc/bash.bashrc | grep -E "^TMOUT.*")"; then
        cat <<EOF | tee -a /etc/bash.bashrc > /dev/null
TMOUT=900
readonly TMOUT
export TMOUT
EOF
    fi

    cat <<EOF | tee /etc/profile.d/timeout.sh > /dev/null
TMOUT=900
readonly TMOUT
export TMOUT
EOF
    
    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 5.7 Ensure access to the su command is restricted (Automated)" "" 1
    
    test -z "$(grep sugroup /etc/group)" && groupadd sugroup

    sed -i /etc/pam.d/su -e 's/#\s*\(auth\s\+required\s\+pam_wheel\.so\)\s*$/\1 use_uid group=sugroup/g'
    
    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

exit 0
