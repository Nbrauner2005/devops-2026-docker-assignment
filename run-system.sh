#!/bin/sh

set -e

docker network create \
    --label com.nathan.assignment=devops-2026-docker \
    devops-assignment-network

