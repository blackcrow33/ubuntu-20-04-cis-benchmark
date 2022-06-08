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

# Download package dependencies.
for i in $(apt-cache depends $1 | grep -E 'Depends|Recommends|Suggests' | cut -d ':' -f 2,3 | sed -e "s/<|>//g"); do 
    sudo apt-get download --print-uris $i | sed -e "s/^'//" -e "s/\(\.deb\)'.*/\1/g" | xargs -I{} wget {}; 
done
# Download the desired package
sudo apt-get download --print-uris $1 | sed -e "s/^'//" -e "s/\(\.deb\)'.*/\1/g" | xargs -I{} wget {}; 
