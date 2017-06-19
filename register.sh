#!/bin/bash

# get credentials from the settings file
source /vagrant/settings

# register with RHEL network
echo "Registering with Redhat"
sudo subscription-manager register --username $USERNAME --password $PASSWORD --auto-attach

# add additional repos 
sudo subscription-manager repos --enable rhel-7-server-optional-rpms
sudo subscription-manager repos --enable rhel-7-server-supplementary-rpms
sudo subscription-manager repos --enable rhel-7-server-thirdparty-oracle-java-rpms

# make the cleaup script executable; this will unregister from RHEL network when vagrant destroy happens
sudo chmod +x /vagrant/cleanup.sh
