#!/bin/bash

say "- 1.1.1.x Ensure mounting of cramfs, freevxfs, jffs2, hfs, hfsplus, udf, usb-storage filesystems is disabled - modprobe" "" 1
    MODS=(cramfs freevxfs jffs2 hfs hfsplus udf usb-storage)
    for mod in ${MODS[*]}; do
        echo "install $mod /bin/true" | tee /etc/modprobe.d/$mod.conf > /dev/null
        if [ $(lsmod | grep $mod | wc -l) -eq 1 ]; then
            rmmod $mod 2> /dev/null
        fi
    done
    
    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi


say "- 1.4.1 Ensure permissions on bootloader config are not overridden (Automated)" "" 1
    
    if [ $(cat /usr/sbin/grub-mkconfig | grep "chmod 444" | wc -l) -gt 0 ]; then
        sed -ri 's/chmod\s+[0-7][0-7][0-7]\s+\$\{grub_cfg\}\.new/chmod 400 ${grub_cfg}.new/' /usr/sbin/grub-mkconfig
        sed -ri 's/ && ! grep "\^password" \$\{grub_cfg\}.new >\/dev\/null//' /usr/sbin/grub-mkconfig
    fi
    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 1.4.2 Ensure bootloader password is set (Automated)" "" 1
    
    if [ $(grep "^set superusers" /boot/grub/grub.cfg | wc -l) -eq 0 -a  $(grep "^password" /boot/grub/grub.cfg | wc -l) -eq 0 ]; then
        echo -e "cat<<EOF\nset superusers=\"sysadmin\"\npassword_pbkdf2 sysadmin grub.pbkdf2.sha512.10000.8E6652B2F2BC5115CDD7B32CCD2CEED43D4A18EDE7B60932AF01FEAA994E52D46E1C1F4611B8D6A8421321D9C6CFCAEEE5A120937D64975898D31AAA7C252A4E.7CE038C68608D13B920644C146B530CD6D887D3598BF881E01B4D7FBDE94C6BDF6519DDB5F7140B2448E2199CCDE9895CE6B99471EBCC56365A5A7ACA2CBE060\nEOF" | tee /etc/grub.d/42_custom >> /dev/null
        chmod 755 /etc/grub.d/42_custom
        sed -e 's/^CLASS=".*"$/CLASS="--class gnu-linux --class gnu --class os --unrestricted"/' -i /etc/grub.d/10_linux 
        update-grub > /dev/null 2>&1
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
This OS is configured and specialized for the ELK related services.
You must have explicit, authorized permission to access or configure this device. 
Unauthorized attempts and actions to access or use this system may result in civil and/or criminal penalties. 
All activities performed on this device are logged and monitored.

EOF
    
    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 1.7.2~1.7.3 Ensure local/remote login warning banner is configured properly" "" 1

    msg="Authorized uses only. All activity may be monitored and reported."
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

say "- 2.1.x Ensure rsync, NFS, telnet, RPC service is not installed" "" 1

    apt-get purge rsync nfs-kernel-server telnet rpcbind -y > /dev/null 2>&1 
    apt-get autoremove -y > /dev/null 2>&1

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi


exit 0
