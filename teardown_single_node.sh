#!/bin/bash
# teardown_single_node.sh
# Tears down a single chrony node provisioned with run_single_node.sh
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

function TearDownSingleNode() {
	stopContainer "single_chrony"

	removeContainer "single_chrony"
}

TearDownSingleNode