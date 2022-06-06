#!/bin/bash
# Download package dependencies.
for i in $(apt-cache depends $1 | grep -E 'Depends|Recommends|Suggests' | cut -d ':' -f 2,3 | sed -e "s/<|>//g"); do 
    sudo apt-get download --print-uris $i | sed -e "s/^'//" -e "s/\(\.deb\)'.*/\1/g" | xargs -I{} wget {}; 
done
# Download the desired package
sudo apt-get download --print-uris $1 | sed -e "s/^'//" -e "s/\(\.deb\)'.*/\1/g" | xargs -I{} wget {}; 
