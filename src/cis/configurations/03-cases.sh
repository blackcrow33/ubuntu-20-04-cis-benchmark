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

say "- 3.2.1 Ensure packet redirect sending is disabled (Automated)" "" 1
    keys=(
        net.ipv4.conf.all.send_redirects
        net.ipv4.conf.default.send_redirects
    )

    vals=(
        0 
        0
    )
    cnt=0
    
    for key in "${keys[@]}"; do
        if [ -z "$(grep -E "^$key" /etc/sysctl.d/*)" ]; then
            echo "$key = ${vals[$cnt]}" >> /etc/sysctl.d/99-sysctl.conf
        fi
        sysctl -w $key=${vals[$cnt]} > /dev/null
        cnt=$((cnt + 1))
    done

    sysctl -w net.ipv4.route.flush=1 > /dev/null
    sysctl -w net.ipv6.route.flush=1 > /dev/null

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 3.2.2 Ensure IP forwarding is disabled (Automated)" "" 1
    # fixed the missing path
    mkdir -p /run/sysctl.d/
    touch /run/sysctl.d/00_custom.conf
    
    grep -Els "^\s*net\.ipv4\.ip_forward\s*=\s*1" /etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /run/sysctl.d/*.conf | \
        while read filename; do 
            sed -ri "s/^\s*(net\.ipv4\.ip_forward\s*)(=)(\s*\S+\b).*$/# *REMOVED* \1/" $filename
        done 
        sysctl -w net.ipv4.ip_forward=0 > /dev/null
        sysctl -w net.ipv4.route.flush=1 > /dev/null

    grep -Els "^\s*net\.ipv6\.conf\.all\.forwarding\s*=\s*1" /etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /run/sysctl.d/*.conf | \
        while read filename; do 
            sed -ri "s/^\s*(net\.ipv6\.conf\.all\.forwarding\s*)(=)(\s*\S+\b).*$/# *REMOVED* \1/" $filename
        done
        sysctl -w net.ipv6.conf.all.forwarding=0 > /dev/null
        sysctl -w net.ipv6.route.flush=1 > /dev/null

    keys=(
        net.ipv4.ip_forward
        net.ipv6.conf.all.forwarding
    )
    for key in "${keys[@]}"; do
        if [ -z "$(grep -E "^$key" /etc/sysctl.d/*)" ]; then
            echo "$key = 0" >> /etc/sysctl.d/99-sysctl.conf
        fi
        sysctl -w $key=0 > /dev/null
    done

    sysctl -w net.ipv4.route.flush=1 > /dev/null
    sysctl -w net.ipv6.route.flush=1 > /dev/null

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 3.3.1 Ensure source routed packets are not accepted (Automated)" "" 1

    keys=(
        net.ipv4.conf.all.accept_source_route
        net.ipv4.conf.default.accept_source_route
        net.ipv6.conf.all.accept_source_route
        net.ipv6.conf.default.accept_source_route
    )
    for key in "${keys[@]}"; do
        if [ -z "$(grep -E "^$key" /etc/sysctl.d/*)" ]; then
            echo "$key = 0" >> /etc/sysctl.d/99-sysctl.conf
        fi
        sysctl -w $key=0 > /dev/null
    done

    sysctl -w net.ipv4.route.flush=1 > /dev/null
    sysctl -w net.ipv6.route.flush=1 > /dev/null
    
    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 3.3.2 Ensure ICMP redirects are not accepted (Automated)" "" 1

    keys=(
        net.ipv4.conf.all.accept_redirects
        net.ipv4.conf.default.accept_redirects
        net.ipv6.conf.all.accept_redirects
        net.ipv6.conf.default.accept_redirects
    )
    for key in "${keys[@]}"; do
        if [ -z "$(grep -E "^$key" /etc/sysctl.d/*)" ]; then
            echo "$key = 0" >> /etc/sysctl.d/99-sysctl.conf
        fi
        sysctl -w $key=0 > /dev/null
    done

    sysctl -w net.ipv4.route.flush=1 > /dev/null
    sysctl -w net.ipv6.route.flush=1 > /dev/null
    
    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 3.3.3 Ensure secure ICMP redirects are not accepted (Automated)" "" 1

    keys=(
        net.ipv4.conf.all.secure_redirects
        net.ipv4.conf.default.secure_redirects
    )
    for key in "${keys[@]}"; do
        if [ -z "$(grep -E "^$key" /etc/sysctl.d/*)" ]; then
            echo "$key = 0" >> /etc/sysctl.d/99-sysctl.conf
        fi
        sysctl -w $key=0 > /dev/null
    done

    sysctl -w net.ipv4.route.flush=1 > /dev/null
    
    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 3.3.4 Ensure suspicious packets are logged (Automated)" "" 1

    keys=(
        net.ipv4.conf.all.log_martians
        net.ipv4.conf.default.log_martians
    )
    for key in "${keys[@]}"; do
        if [ -z "$(grep -E "^$key" /etc/sysctl.d/*)" ]; then
            echo "$key = 1" >> /etc/sysctl.d/99-sysctl.conf
        fi
        sysctl -w $key=1 > /dev/null
    done

    sysctl -w net.ipv4.route.flush=1 > /dev/null
    
    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 3.3.5~3.3.6 Ensure broadcast ICMP requests & bogus ICMP responeses are ignored (Automated)" "" 1

    keys=(
        net.ipv4.icmp_echo_ignore_broadcasts
        net.ipv4.icmp_ignore_bogus_error_responses
    )
    for key in "${keys[@]}"; do
        if [ -z "$(grep -E "^$key" /etc/sysctl.d/*)" ]; then
            echo "$key = 1" >> /etc/sysctl.d/99-sysctl.conf
        fi
        sysctl -w $key=1 > /dev/null
    done

    sysctl -w net.ipv4.route.flush=1 > /dev/null
    
    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 3.3.7 Ensure Reverse Path Filtering is enabled (Automated)" "" 1

    sed -e 's/^\(net\.ipv4\.conf\..*\.rp_filter\)=.*$/\1=1/g' -i /etc/sysctl.d/10-network-security.conf > /dev/null
    sysctl -w net.ipv4.route.flush=1 > /dev/null
    
    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 3.3.8 Ensure TCP SYN Cookies is enabled (Automated)" "" 1
    
    sed -e 's/#\?\(net\.ipv4\.tcp_syncookies=.*\)$/\1/g' -i /etc/sysctl.d/99-sysctl.conf
    sysctl -w net.ipv4.tcp_syncookies=1 > /dev/null
    sysctl -w net.ipv4.route.flush=1 > /dev/null
    
    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 3.3.9 Ensure IPv6 router advertisements are not accepted (Automated)" "" 1

    keys=(
        net.ipv6.conf.all.accept_ra
        net.ipv6.conf.default.accept_ra
    )
    for key in "${keys[@]}"; do
        if [ -z "$(grep -E "^$key" /etc/sysctl.d/*)" ]; then
            echo "$key = 0" >> /etc/sysctl.d/99-sysctl.conf
        fi
        sysctl -w $key=0 > /dev/null
    done

    sysctl -w net.ipv6.route.flush=1 > /dev/null
    
    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 3.5.3.1.x Ensure iptables packages are installed (Automated)" "" 1

    if [ -n "$(dpkg -s ufw 2>&1 | grep "install ok installed")" ]; then
        ufw disable > /dev/null
        apt-get purge -y ufw > /dev/null 2>&1
    fi

    echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
    echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections

    tar -zxf $WORKDIR/packages/iptables-all.tar.gz -C /var/cache/apt/archives/
    DEBIAN_FRONTEND=noninteractive apt-get -q install -y iptables-persistent 1> /dev/null 

    # create a shortcut in /sbin since the tenable is assumed the iptables command is 
    # on the /sbin path
    if [[ ! -f /sbin/iptables ]]; then
        ln -s /usr/sbin/iptables /sbin/iptables
    fi
    if [[ ! -f /sbin/ip6tables ]]; then
        ln -s /usr/sbin/ip6tables /sbin/ip6tables
    fi

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 3.5.3.2 Ensure iptables packages are installed (Automated)" "" 1
    
    # backup the iptables rules before doing the following steps
    [ -f /etc/iptables/rules.v4 ] && mv /etc/iptables/rules.v4{,.old}
    [ -f /etc/iptables/rules.v6 ] && mv /etc/iptables/rules.v6{,.old}
    
    for i in `iptables -L INPUT --line-numbers |grep '[0-9].*ufw' | cut -f 1 -d ' ' | sort -r `; do iptables -D INPUT $i ; done
    for i in `iptables -L FORWARD --line-numbers |grep '[0-9].*ufw' | cut -f 1 -d ' ' | sort -r `; do iptables -D FORWARD $i ; done
    for i in `iptables -L OUTPUT --line-numbers |grep '[0-9].*ufw' | cut -f 1 -d ' ' | sort -r `; do iptables -D OUTPUT $i ; done
    for i in `iptables -L | grep 'Chain .*ufw' | cut -d ' ' -f 2`; do iptables -X $i ; done

    iptables -F; \
    # Ensure default deny firewall policy
    iptables -P INPUT DROP; \
    iptables -P OUTPUT DROP; \
    iptables -P FORWARD DROP; \
    # Ensure loopback traffic is configured
    iptables -A INPUT -i lo -j ACCEPT; \
    iptables -A OUTPUT -o lo -j ACCEPT; \
    iptables -A INPUT -s 127.0.0.0/8 -j DROP; \
    # Ensure outbound and established connections are configured
    iptables -A OUTPUT -p tcp -m state --state NEW,ESTABLISHED -j ACCEPT; \
    iptables -A OUTPUT -p udp -m state --state NEW,ESTABLISHED -j ACCEPT; \
    iptables -A OUTPUT -p icmp -m state --state NEW,ESTABLISHED -j ACCEPT; \
    iptables -A INPUT -p tcp -m state --state ESTABLISHED -j ACCEPT; \
    iptables -A INPUT -p udp -m state --state ESTABLISHED -j ACCEPT; \
    iptables -A INPUT -p icmp -m state --state ESTABLISHED -j ACCEPT; \
    # Open inbound ssh(tcp port 22) connections
    iptables -A INPUT -p tcp --dport 22 -m state --state NEW -j ACCEPT; \
    # Save the rule for persistent usage
    iptables-save > /etc/iptables/rules.v4

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 3.5.3.3 Configure IPv6 ip6tables" "" 1

    for i in `ip6tables -L INPUT --line-numbers |grep '[0-9].*ufw6' | cut -f 1 -d ' ' | sort -r `; do ip6tables -D INPUT $i ; done
    for i in `ip6tables -L FORWARD --line-numbers |grep '[0-9].*ufw6' | cut -f 1 -d ' ' | sort -r `; do ip6tables -D FORWARD $i ; done
    for i in `ip6tables -L OUTPUT --line-numbers |grep '[0-9].*ufw6' | cut -f 1 -d ' ' | sort -r `; do ip6tables -D OUTPUT $i ; done
    for i in `ip6tables -L | grep 'Chain .*ufw6' | cut -d ' ' -f 2`; do ip6tables -X $i ; done

    # Flush ip6tables rules
    ip6tables -F; \
    # Ensure default deny firewall policy
    ip6tables -P INPUT DROP; \
    ip6tables -P OUTPUT DROP; \
    ip6tables -P FORWARD DROP; \
    # Ensure loopback traffic is configured
    ip6tables -A INPUT -i lo -j ACCEPT; \
    ip6tables -A OUTPUT -o lo -j ACCEPT; \
    ip6tables -A INPUT -s ::1 -j DROP; \
    # Ensure outbound and established connections are configured ip6tables -A OUTPUT -p tcp -m state --state NEW,ESTABLISHED -j ACCEPT
    ip6tables -A OUTPUT -p udp -m state --state NEW,ESTABLISHED -j ACCEPT; \
    ip6tables -A OUTPUT -p icmp -m state --state NEW,ESTABLISHED -j ACCEPT; \
    ip6tables -A INPUT -p tcp -m state --state ESTABLISHED -j ACCEPT; \
    ip6tables -A INPUT -p udp -m state --state ESTABLISHED -j ACCEPT; \
    ip6tables -A INPUT -p icmp -m state --state ESTABLISHED -j ACCEPT; \
    # Open inbound ssh(tcp port 22) connections
    ip6tables -A INPUT -p tcp --dport 22 -m state --state NEW -j ACCEPT; \
    ip6tables-save > /etc/iptables/rules.v6

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

exit 0

