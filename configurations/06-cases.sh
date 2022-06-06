#!/bin/bash

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

    if [ $? -eq 0 ]; then sayDone; else sayFailed; fi

say "- 6.2.4 Ensure all users' home directories exist (Automated)" "" 1

    awk -F: '($1!~/(halt|sync|shutdown|nfsnobody)/ && $7!~/^(\/usr)?\/sbin\/nologin(\/)?$/ && $7!~/(\/usr)?\/bin\/false(\/)?$/) { print $1 " " $6 }' \
        /etc/passwd | \
        while read -r user dir; do
            if [ ! -d "$dir" ]; then
                mkdir $dir
                chmod g-w,o-wrx $dir
                chown $user $dir
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
