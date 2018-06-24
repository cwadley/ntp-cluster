#!/bin/bash
# teardown_cluster.sh
# Tears down a chrony cluster provisioned with provision_cluster.sh
source chrony_vars.sh

# $1 - Container name
function stopContainer() {
	echo "Stopping container $1..."
	docker stop $1
}

# $1 - Container name
function removeContainer() {
	echo "Removing container $1..."
	docker rm $1
}

# $1 - Network name
function removeNetwork() {
	echo "Removing network $1..."
	docker network rm $1
}

function TearDownCluster() {
	nodeCount=${#chrony_cluster[@]}
	stopContainer $loadbalancer

	for (( i=0; i<${nodeCount}; i++ )); do
		stopContainer "chrony_$i"
	done

	removeContainer $loadbalancer

	for (( i=0; i<${nodeCount}; i++ )); do
		removeContainer "chrony_$i"
	done

	removeNetwork $network_name

}

TearDownCluster