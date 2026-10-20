#!/bin/sh

set -e

LABEL="com.nathan.assignment=devops-2026-docker"

echo "Creating Docker network..."

docker network create \
    --label "$LABEL" \
    devops-assignment-network

echo "Creating PostgreSQL volume..."

docker volume create \
    --label "$LABEL" \
    devops-postgres-data

echo "Starting PostgreSQL..."

docker run -d \
    --name postgres-db \
    --network devops-assignment-network \
    --label "$LABEL" \
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

echo "Building database seeder..."

docker build --target seeder \
    --label "$LABEL" \
    -t devops-assignment-seeder:1.0 .

echo "Starting database seeder..."

docker run --rm \
    --name db-seeder \
    --network devops-assignment-network \
    --label "$LABEL" \
    -v "${PWD}/Chinook.db:/app/Chinook.db:ro" \
    -e SQLITE_FILE=/app/Chinook.db \
    -e DATABASE_URL="postgres://devops:devops123@postgres-db:5432/chinook" \
    devops-assignment-seeder:1.0

echo "Database seeding complete."

echo "Starting MCP Gateway..."

docker run -d \
    --name mcp-gateway \
    --network devops-assignment-network \
    --label "$LABEL" \
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

echo "Starting AI Agent..."

docker build --target agent \
    --label "$LABEL" \
    -t devops-assignment-agent:1.0 .

docker run --rm \
    --name ai-agent \
    --network devops-assignment-network \
    --label "$LABEL" \
    -v "${PWD}/secret.ollama-api-key:/run/secrets/openai-api-key:ro" \
    -e MCP_SERVER_URL="http://mcp-gateway:8811/sse" \
    -e DATABASE_DIALECT="PostgreSQL" \
    -e QUESTION="What are the top 3 albums by sales? Cast the total sales calculation to double precision so the results can be returned as JSON." \
    -e OPENAI_API_BASE_URL="https://ollama.com/v1" \
    -e OPENAI_MODEL_NAME="gpt-oss:20b" \
    devops-assignment-agent:1.0

echo "AI Agent completed."