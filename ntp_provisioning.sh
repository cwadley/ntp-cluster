#!/bin/bash
# Configures CentOS to run an NTP pool server as a docker container using chrony

# Edit these variables

# Array of the domains or IP addresses of the external NTP servers that will be used to sync each chrony node
declare -a sync_servers=("time-b.nist.gov" "us-ny.ntp.dark-net.io" "e.time.steadfast.net" "fuzz.psc.edu" "clock.psu.edu" "bonehed.lcs.mit.edu")
# Friendly name of the Docker network the cluster will share
ntp_network="ntp_cluster"
# CIDR of the address range covered by the Docker network (ex. 192.168.0.0/24)
ntp_network_CIDR=192.168.0.0/24
# Docker network IP address of the nginx loadbalancer container (must be within the network CIDR range)
ntp_loadbalancer=192.168.0.1
# Array of the IP addresses of the chrony nodes in the cluster (must be within the network CIDR range. Node count is inferred from the array length)
declare -a chrony_cluster=(192.168.0.2 192.168.0.3 192.168.0.4 192.168.0.5)

function updateAndInstallDocker() {
	echo "Updating machine..."
	yum update -y
	echo "Installing Docker..."
	yum install -y yum-utils device-mapper-persistent-data lvm2
	yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
	yum install -y docker-ce
	systemctl start docker
	systemctl enable docker
}

function enableIPTABLES() {
	echo "Disabling firewalld..."
	systemctl stop firewalld
	systemctl mask firewalld
	echo "Installing and enabling iptables..."
	yum install -y iptables-services
	systemctl enable iptables
	systemctl enable ip6tables
	systemctl start iptables
	systemctl start ip6tables
}

function configureIPTABLES() {
	echo "Setting up IPTABLES ruleset..."

	# Temporarily set the default behavior for incoming connections to accept to prevent SSH from being locked out
	iptables -P INPUT ACCEPT
	ip6tables -P INPUT ACCEPT

	# Flush the current ruleset
	iptables -F
	ip6tables -F

	# Accept local connections to localhost
	iptables -A INPUT -i lo -j ACCEPT
	ip6tables -A INPUT -i lo -j ACCEPT

	# Accept all incoming connections that are part of an already established connection
	iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	ip6tables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

	# Accept SSH connections on port 22
	iptables -A INPUT -p tcp --dport 22 -j ACCEPT
	ip6tables -A INPUT -p tcp --dport 22 -j ACCEPT

	# Accept NTP connections on port 123
	iptables -A INPUT -p udp --dport 123 -j ACCEPT
	ip6tables -A INPUT -p udp --dport 123 -j ACCEPT

	# Don't track NTP connections
	iptables -t raw -A PREROUTING -p udp --dport 123 -j CT --notrack
	ip6tables -t raw -A PREROUTING -p udp --dport 123 -j CT --notrack
	iptables -t raw -A OUTPUT -p udp --sport 123 -j CT --notrack
	ip6tables -t raw -A OUTPUT -p udp --sport 123 -j CT --notrack

	# Reset the default behavior for incoming connections from accept to drop
	iptables -P INPUT DROP
	ip6tables -P INPUT DROP

	# No packet forwarding will happen on this machine, so drop all forwarding packets
	iptables -P FORWARD DROP
	ip6tables -P FORWARD DROP

	# Allow all outbound traffic
	iptables -P OUTPUT ACCEPT
	ip6tables -P OUTPUT ACCEPT

	# List out the ruleset
	echo "Finished setting up IPTABLES ruleset."
	iptables -L -v
	ip6tables -L -v
	
	service iptables save
	service ip6tables save
}

function pullDockerImages() {
	echo "Pulling chrony and nginx docker images..."
	docker pull cwadley/alpine-chrony
	docker pull nginx
}

# $1 - Array reference of external NTP servers which will be used to sync the NTP nodes
function configureChronyConf() {
	echo "Configuring chrony.conf..."
	local serverz=("$@")

	cp chrony.conf /etc/chrony.conf
	serverConfig=""
	for srv in "${serverz[@]}"; do
		serverConfig="${serverConfig} \nserver ${srv} iburst"
	done
	sed -i -e "s|{{servers}}|$serverConfig|g" /etc/chrony.conf
}

# $1 - Array reference of NTP node IP addresses
function configureNginx() {
	echo "Configuring nginx.conf..."
	local nodez=("$@")

	cp nginx.conf /etc/nginx.conf
	ntpNodes=""
	for ip in "${1[@]}"; do
		ntpNodes="${ntpNodes} \nserver ${ip}:123;"
	done
	sed -i -e "s|{{ntp_nodes}}|$ntpNodes|g" /etc/nginx.conf
}

# $1 - NTP network name
# $2 - NTP network CIDR
# $3 - LoadBalancer IP
function setUpDockerNetwork() {
	echo "Setting up Docker network..."
	docker network create --subnet=$2 $1
	docker run -d \
	--name nginx \
	--network $1 \
	--ip $3 \
	-p 123:123/udp \
	-v /etc/nginx.cfg:/etc/nginx/nginx.conf:ro \
	-v /var/log/nginx:/var/log/nginx \
	nginx
}

# $1 - Node name
# $2 - Node IP
# $3 - NTP network name
function runChronyDocker() {
	echo "Running chrony container node: $1"
	docker run -d \
	--name $1 \
	--network $3 \
	--ip $2 \
	-v /etc/ntp.conf:/etc/ntp.conf:ro \
	cwadley/alpine-chrony
}

function ConfigureMachine() {
	updateAndInstallDocker
	enableIPTABLES
	configureIPTABLES
	pullDockerImages
	configureChronyConf "${sync_servers[@]}"
	configureNginx "${chrony_cluster[@]}"
	setUpDockerNetwork $ntp_network $ntp_network_CIDR $ntp_loadbalancer

	i=0
	for node_ip in "${chrony_cluster[@]}"; do
		runChronyDocker "chrony_$i" "$node_ip" $ntp_network
		((i++))
	done
}

ConfigureMachine