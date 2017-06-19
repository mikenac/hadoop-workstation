#!/bin/bash

# unsubscribe this VM from RHEL network
sudo subscription-manager remove --all
sudo subscription-manager unregister
sudo subscription-manager clean
