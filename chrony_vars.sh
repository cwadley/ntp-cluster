#!/bin/bash
# chrony_vars.sh
# These variables are used in provision_cluster.sh and teardown_cluster.sh

### Edit these variables
# Array of the domains or IP addresses of the external NTP servers that will be used to sync each chrony node
declare -a sync_servers=("time-b.nist.gov" "us-ny.ntp.dark-net.io" "e.time.steadfast.net" "fuzz.psc.edu" "clock.psu.edu" "bonehed.lcs.mit.edu")

# Array of the IP addresses of the chrony nodes in the cluster 
# For multi-machine cluster configurations, these are domain names or IP addresses of the chrony node machines in the cluster.
# For single-machine cluster configurations, these must be within the network CIDR range defined below. Node count is inferred from the array length.
declare -a chrony_cluster=(192.168.0.3 192.168.0.4 192.168.0.5 192.168.0.6)


### Single-machine cluster configuration - only used when running run_cluster.sh
# Friendly name of the Docker network the cluster will share
network_name="chrony_cluster"

# CIDR of the address range covered by the Docker network (ex. 192.168.0.0/24)
network_CIDR=192.168.0.0/24

# Docker network IP address of the nginx loadbalancer container (must be within the network CIDR range)
loadbalancer=192.168.0.2
