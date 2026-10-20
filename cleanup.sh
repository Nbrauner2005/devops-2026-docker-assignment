#!/bin/sh

set -e

LABEL="com.nathan.assignment=devops-2026-docker"

echo "Cleaning up DevOps assignment resources..."

echo "Removing containers..."

docker ps -aq --filter "label=$LABEL" | xargs -r docker rm -f

echo "Removing volumes..."

docker volume ls -q --filter "label=$LABEL" | xargs -r docker volume rm

echo "Removing network..."

docker network ls -q --filter "label=$LABEL" | xargs -r docker network rm

echo "Removing images..."

docker images -q --filter "label=$LABEL" | xargs -r docker rmi -f

echo "Cleanup complete."