#! /bin/bash

# Setup Swap space
sudo fallocate -l 4G /mnt/4GB.swap
sudo mkswap /mnt/4GB.swap
sudo swapon /mnt/4GB.swap
sudo chmod 600 /mnt/4GB.swap
sudo sh -c 'echo /mnt/4GB.swap  none  swap  sw 0  0  >> /etc/fstab'
