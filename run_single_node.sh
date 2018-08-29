#!/bin/bash
# run_single_node.sh
# Runs a single chrony server container without the nginx load balancer, using the first IP address in the chrony_cluster array
source chrony_vars.sh

# $1 - Node name
# $2 - Node IP
function runSingleChronyNode() {
	echo "Running chrony container node: $1"
	docker run -d \
	--name $1 \
	--ip $2 \
	-p 123:123/udp \
	-v /etc/chrony.conf:/etc/chrony/chrony.conf:ro \
	--cap-add SYS_NICE \
    --cap-add SYS_TIME \
    --cap-add SYS_RESOURCE \
	cwadley/alpine-chrony
}

function RunSingleChronyNode() {
	runSingleChronyNode "single_chrony" "${chrony_cluster[0]}"
}