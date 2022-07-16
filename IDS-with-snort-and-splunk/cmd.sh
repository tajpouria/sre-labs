# Running snort in self-test mode
snort -T -c /etc/snort/snort.conf

# Running snort in Alarm mode logging into console (Experimenting)
snort -q -l /var/log/snort -A console -c /etc/snort/snort.conf

# Running snort in Fast Alarm mode
snort -q -l /var/log/snort -A Fast -c /etc/snort/snort.conf
