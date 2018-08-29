#!/bin/bash
# run_single_node.sh
# Runs a single chrony server container without the nginx load balancer

# $1 - Node name
function runSingleChronyNode() {
	echo "Running chrony container node: $1"
	docker run -d \
	--name $1 \
	-p 123:123/udp \
	-v /etc/chrony.conf:/etc/chrony/chrony.conf:ro \
	--cap-add SYS_NICE \
    --cap-add SYS_TIME \
    --cap-add SYS_RESOURCE \
	cwadley/alpine-chrony
}

function RunSingleChronyNode() {
	runSingleChronyNode "single_chrony"
}

RunSingleChronyNode