#!/bin/bash
scp -r * root@172.16.202.128:/root/cis-fix/
ssh root@172.16.202.128 bash -c "./cis-fix/run.sh"
