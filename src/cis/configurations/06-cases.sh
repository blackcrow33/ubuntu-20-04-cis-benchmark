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

say "- 6.1.6 Ensure permissions on /etc/shadow are configured (Automated)" "" 1

    # https://support.hcltechsw.com/csm?id=kb_article&sysparm_article=KB0080703
    # https://askubuntu.com/questions/827608/why-is-the-file-permission-for-etc-shadow-set-to-600

    # The system default is applied to the CIS benchmark but the tenable prompt this check 
    # is an uneven permission, we do not find any unevent permission on the file /etc/shadow
    # and /etc/shadow-, whose the permission of two files are 0640 and root:shadow 
    # for the owner:group 

    # try to change the owner to root only instead of root:shadow. 
    chown root:root /etc/shadow
    chmod u-x,g-wx,o-rwx /etc/shadow

    chown root:root /etc/shadow-
    chmod u-x,g-wx,o-rwx /etc/shadow-

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi


say "- 6.1.10 Ensure no world writable files exist" "" 1
    
    for file in $(df --local -P | awk '{if (NR!=1) print $6}' | xargs -I '{}' find '{}' -xdev -type f -perm -0002); do
        chmod o-rwx $file
    done
    
    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 6.2.4 Ensure all users' home directories exist (Automated)" "" 1

    awk -F: '($1!~/(halt|sync|shutdown|nfsnobody)/ && $7!~/^(\/usr)?\/sbin\/nologin(\/)?$/ && $7!~/(\/usr)?\/bin\/false(\/)?$/) { print $1 " " $6 }' \
        /etc/passwd | \
        while read -r user dir; do
            if [ ! -d "$dir" ]; then
                mkdir -p $dir
            fi

            chmod g-w,o-wrx $dir
            chown $user $dir
        done

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 6.2.5 Ensure users own their home directories (Automated)" "" 1
    
    awk -F: '($1!~/(halt|sync|shutdown)/ && $7!~/^(\/usr)?\/sbin\/nologin(\/)?$/ && $7!~/(\/usr)?\/bin\/false(\/)?$/) { print $1 " " $6 }' \
       /etc/passwd | while read -r user dir; do
            if [ ! -d "$dir" ]; then
                echo "User: \"$user\" home directory: \"$dir\" does not exist, creating home directory"
                mkdir "$dir"
                chmod g-w,o-rwx "$dir"
                chown "$user" "$dir"
            else
                owner=$(stat -L -c "%U" "$dir")
                if [ "$owner" != "$user" ]; then
                    chmod g-w,o-rwx "$dir"
                    chown "$user" "$dir"
                fi
            fi 
        done
    

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 6.2.6 Ensure users' home directories permissions are 750 or more restrictive (Automated)" "" 1
    awk -F: '($1!~/(halt|sync|shutdown)/ && $7!~/^(\/usr)?\/sbin\/nologin(\/)?$/ && $7!~/(\/usr)?\/bin\/false(\/)?$/) {print $6}' \
        /etc/passwd | \
        while read -r dir; do
            if [ -d "$dir" ]; then
                dirperm=$(stat -L -c "%A" "$dir")
                if [ "$(echo "$dirperm" | cut -c6)" != "-" ] \
                    || [ "$(echo "$dirperm" | cut -c8)" != "-" ] \
                    || [ "$(echo "$dirperm" | cut -c9)" != "-" ] \
                    || [ "$(echo "$dirperm" | cut -c10)" != "-" ]; then

                    chmod g-w,o-rwx "$dir"
                fi
            fi 
        done

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 6.2.7 Ensure users' dot files are not group or world writable" "" 1

    awk -F: '($1!~/(halt|sync|shutdown)/ && $7!~/^(\/usr)?\/sbin\/nologin(\/)?$/ && $7!~/(\/usr)?\/bin\/false(\/)?$/) { print $1 " " $6 }' \
        /etc/passwd | while read -r user dir; do
            if [ -d "$dir" ]; then
                for file in "$dir"/.*; do
                    if [ ! -h "$file" ] && [ -f "$file" ]; then
                        fileperm=$(stat -L -c "%A" "$file")
                        if [ "$(echo "$fileperm" | cut -c6)" != "-" ] || [ "$(echo "$fileperm" | cut -c9)" != "-" ]; then
                            chmod go-w "$file"
                        fi 
                    fi
                done 
            fi
        done

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi
exit 0
