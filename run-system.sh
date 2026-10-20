#!/bin/sh

set -e

docker network create \
    --label com.nathan.assignment=devops-2026-docker \
    devops-assignment-network

docker run -d \
    --name postgres-db \
    --network devops-assignment-network \
    --label com.nathan.assignment=devops-2026-docker \
    -e POSTGRES_USER=devops \
    -e POSTGRES_PASSWORD=devops123 \
    -e POSTGRES_DB=chinook \
    -v devops-postgres-data:/var/lib/postgresql/data \
    postgres:17

echo "Waiting for PostgreSQl..."

until docker exec postgres-db pg_isready -U devops -d chinook >/dev/null 2>&1
do
    sleep 2
done

echo "PostgreSQL is ready."

docker build --target seeder -t devops-assignment-seeder:1.0 . 
