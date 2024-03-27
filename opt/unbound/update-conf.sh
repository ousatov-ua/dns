#!/bin/bash

# IANA as source for root hints
# wget https://www.internic.net/domain/root.zone -O /etc/unbound/root.zone

# Update rules
curl -o "/etc/unbound/rules/hagezy-multi-normal.conf" "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/unbound/multi.blacklist.conf"
curl -o "/etc/unbound/rules/hagezy-gambling.conf" "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/unbound/gambling.blacklist.conf"
curl -o "/etc/unbound/rules/oisd-nsfw.conf" "https://nsfw.oisd.nl/unbound"
curl -o "/etc/unbound/rules/hagezy-anti-privacy.conf" "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/unbound/anti.piracy.blacklist.conf"
curl -o "/etc/unbound/rules/hagezy-no-safe-search.conf" "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/unbound/nosafesearch.blacklist.conf"
curl -o "/etc/unbound/rules/hagezy-threat.conf" "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/unbound/tif.blacklist.conf"
curl -o "/etc/unbound/rules/olus.conf" "https://raw.githubusercontent.com/ousatov-ua/dns-filters/main/unbound/olus.conf"

# Reload config
unbound-control reload_keep_cache
