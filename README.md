# chrony NTP server cluster on CentOS
These scripts assume a fresh CentOS 7 install

## Usage
1. Edit chrony_vars.sh, changing the following variables:
	* sync_servers - Array of the domains or IP addresses of the external NTP servers that will be used to sync each chrony node
	* ntp_network - Friendly name of the Docker network the cluster will share
	* ntp_network_CIDR - CIDR of the address range covered by the Docker network (ex. 192.168.0.0/24)
	* ntp_loadbalancer - Docker network IP address of the nginx loadbalancer container (must be within the network CIDR range)
	* ntp_cluster - Array of the IP addresses of the chrony nodes in the cluster (must be within the network CIDR range. Node count is inferred from the array length)
2. To configure the machine to run the cluster, run configure_machine.sh as sudo:
	`sudo ./configure_machine.sh`
3. To run the cluster, run run_cluster.sh as sudo:
	`sudo ./run_cluster.sh`
4. To tear down the cluster, run teardown_cluster.sh as sudo:
	`sudo ./teardown_cluster.sh