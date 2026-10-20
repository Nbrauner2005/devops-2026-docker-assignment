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

echo "Waiting for PostgreSQL..."

until docker exec postgres-db pg_isready -U devops -d chinook >/dev/null 2>&1
do
    sleep 2
done

echo "PostgreSQL is ready."

docker build --target seeder -t devops-assignment-seeder:1.0 .

echo "Starting database seeder..."

docker run --rm \
    --name db-seeder \
    --network devops-assignment-network \
    --label com.nathan.assignment=devops-2026-docker \
    -v "${PWD}/Chinook.db:/app/Chinook.db:ro" \
    -e SQLITE_FILE=/app/Chinook.db \
    -e DATABASE_URL="postgres://devops:devops123@postgres-db:5432/chinook" \
    devops-assignment-seeder:1.0

echo "Database seeding complete."  

echo "Starting MCP Gateway..."

docker run -d \
    --name mcp-gateway \
    --network devops-assignment-network \
    --label com.nathan.assignment=devops-2026-docker \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "${PWD}/mcp_config.yaml:/mcp_config.yaml:ro" \
    -v "${PWD}/mcp_secret.env:/run/secrets/database-url:ro" \
    docker/mcp-gateway:latest \
    --transport=sse \
    --secrets=/run/secrets/database-url \
    --allow-unauthenticated \
    --servers=cockroachdb \
    --tools=execute_query \
    --config=/mcp_config.yaml

echo "MCP Gateway started."