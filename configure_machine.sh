#!/bin/bash
# configure_machine.sh
# Configures CentOS to run a cluster of chrony NTP servers with nginx loadbalancer in Docker containers
source chrony_vars.sh

function updateAndInstallDocker() {
	echo "Updating machine..."
	yum update -y
	echo "Installing Docker..."
	yum install -y yum-utils device-mapper-persistent-data lvm2
	yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
	yum install -y docker-ce
	systemctl start docker
	systemctl enable docker
	yum install -y ntpdate
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
	for ip in "${nodez[@]}"; do
		ntpNodes="${ntpNodes} \n        server ${ip}:123;"
	done
	sed -i -e "s|{{ntp_nodes}}|$ntpNodes|g" /etc/nginx.conf
}

function ConfigureMachine() {
	updateAndInstallDocker
	enableIPTABLES
	configureIPTABLES
	pullDockerImages
	configureChronyConf "${sync_servers[@]}"
	configureNginx "${chrony_cluster[@]}"
}

ConfigureMachine