#!/bin/bash
# run_single_loadbalancer.sh
# Runs a single nginx loadbalancer with the configured CNAMES or IP addresses

function runNginxLoadbalancer() {
	echo "Running NGINX loadbalancer..."
	docker run -d \
	--name nginx \
	-p 123:123/udp \
	-v /etc/nginx.conf:/etc/nginx/nginx.conf:ro \
	-v /var/log/nginx:/var/log/nginx \
	nginx
}