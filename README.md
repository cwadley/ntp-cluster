# chrony NTP server cluster on CentOS
These scripts assume a fresh CentOS 7 install

## Usage
1. Edit ntp_provisioning.sh, changing the following variables:
	* sync_servers - Array of the domains or IP addresses of the external NTP servers that will be used to sync each chrony node
	* ntp_network - Friendly name of the Docker network the cluster will share
	* ntp_network_CIDR - CIDR of the address range covered by the Docker network (ex. 192.168.0.0/24)
	* ntp_loadbalancer - Docker network IP address of the nginx loadbalancer container (must be within the network CIDR range)
	* ntp_cluster - Array of the IP addresses of the chrony nodes in the cluster (must be within the network CIDR range. Node count is inferred from the array length)
2. Run ntp_provisioning.sh as sudo:
	`sudo ./ntp_provisioning.sh`