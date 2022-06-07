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

# Set the superuser password for the bootloader
# 1.4.2 Ensure bootloader password is set
BOOT_PASSWORD=""
```

## Adding firewall rule

```sh

# Basic usage
iptables -A INPUT -p <protocol> --dport <port> -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p <protocol> --sport <port> -m conntrack --ctstate ESTABLISHED -j ACCEPT

# Saving the firewall rule to /etc/iptables/rules.v4
netfilter-persistent save

# Reload the firewall rules
netfilter-persistent reload

# Allow http port
iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport 80 -m conntrack --ctstate ESTABLISHED -j ACCEPT

# Allow https port
iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport 443 -m conntrack --ctstate ESTABLISHED -j ACCEPT

# Allow elasticsearch port
iptables -A INPUT -p tcp -m multiport --dports 9200,9300 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp -m multiport --sport 9200,9300 -m conntrack --ctstate ESTABLISHED -j ACCEPT

# Allow elasticsearch port and from specified source address
iptables -A INPUT -p tcp -s 192.168.1.0/24 -m multiport --dports 9200,9300 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp -m multiport --sport 9200,9300 -m conntrack --ctstate ESTABLISHED -j ACCEPT
 
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
