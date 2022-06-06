# Getting Started

## Change the settings for each environment

Update the files in `cis/envs/settings.production` or 'cis/envs/settings.staging'

```sh
# Assign the central log server ip
REMOTE_SYSLOG_SERVER=""

# Assign the DNS domain
REMOTE_DNS_DOMAIN="example.com"

# Assign the FQDN or IP of DNS server 
REMOTE_DNS_SERVER=""

# Assign the fallback FQDN or IP of DNS server, using the same ip above is fine
REMOTE_FALLBACK_DNS_SERVER=""

# Assign the FQDN or IP of NTP server
REMOTE_NTP_SERVER=""

# Assign the FQDN or IP of NTP server, using the same ip above is fine
REMOTE_FALLBACK_NTP_SERVER=""
```

## Adding firewall rule

```sh
iptables -A INPUT -p <protocol> --dport <port> -m state --state NEW -j ACCEPT
```
 
## Running the CIS scripts

Run the script to sync the file into remote server and execute the remediation of CIS benchmark.
The environment variable is default as **production** if you omit the value of it.

**supported environments**:

- production
- staging

```sh
chmod u+x ./sync.sh
# e.g. ./sync.sh 192.168.8.8 staging
# e.g. ./sync.sh 192.168.8.8

./sync.sh <MACHINE_IP> <ENVIRONMENT:production>
```
