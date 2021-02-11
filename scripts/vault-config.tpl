#!/bin/bash

# sleep for net configs to take effect
sleep 90s
# restart network services in case nat wasn't fully there
#sudo systemctl status NetworkManager.service
touch /tmp/log.txt
echo "about to do apt-get install software" >> /tmp/log.txt
# Need this to do apt-add-repository
sudo apt-get install software-properties-common

#add hashi repo
sudo curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install vault

# Install some software
sudo apt-get update -y
sudo apt-get install wget -y


# Create some files to hold some info for us
touch /tmp/consul-version
touch /tmp/my-ip


# get IP
export IP_INTERNAL=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
echo $IP_INTERNAL >> /tmp/my-ip





echo "Finished script" >> /tmp/vault-status
