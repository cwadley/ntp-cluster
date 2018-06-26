#!/bin/bash
# run_cluster.sh
# Runs the chrony cluster with nginx loadbalancer
source chrony_vars.sh

# $1 - NTP network name
# $2 - NTP network CIDR
function setUpDockerNetwork() {
	echo "Setting up Docker network..."
	docker network create -d bridge --subnet=$2 $1
}

# $1 - NTP network name
# $2 - LoadBalancer IP
function runNginxLoadbalancer() {
	echo "Running NGINX loadbalancer..."
	docker run -d \
	--name nginx \
	--network $1 \
	--ip $2 \
	-p 123:123/udp \
	-v /etc/nginx.conf:/etc/nginx/nginx.conf:ro \
	-v /var/log/nginx:/var/log/nginx \
	nginx
}

# $1 - Node name
# $2 - Node IP
# $3 - NTP network name
function runChronyNode() {
	echo "Running chrony container node: $1"
	docker run -d \
	--name $1 \
	--network $3 \
	--ip $2 \
	-v /etc/chrony.conf:/etc/chrony/chrony.conf:ro \
	--cap-add SYS_NICE \
    --cap-add SYS_TIME \
    --cap-add SYS_RESOURCE \
	cwadley/alpine-chrony
}

function RunCluster() {
	setUpDockerNetwork $network_name $network_CIDR
	runNginxLoadbalancer $network_name $loadbalancer

	i=0
	for node_ip in "${chrony_cluster[@]}"; do
		runChronyNode "chrony_$i" "$node_ip" $network_name
		((i++))
	done
}

RunCluster