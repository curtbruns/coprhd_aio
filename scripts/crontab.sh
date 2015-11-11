#! /bin/bash
# Schedule ntp update every minute in case host goes to standby
# Good for laptop hosts instead of using ntpd

# Echo new cron into cron file
cat > /home/vagrant/ntp_update.sh << EOF1
sudo ntpdate -s time.nist.gov
EOF1
chmod +x /home/vagrant/ntp_update.sh


# Write out current crontab
crontab -l > /home/vagrant/tmp.cron
cat >> /home/vagrant/tmp.cron << EOF2
* * * * * /home/vagrant/ntp_update.sh
EOF2

#install new cron file
crontab /home/vagrant/tmp.cron
rm /home/vagrant/tmp.cron
