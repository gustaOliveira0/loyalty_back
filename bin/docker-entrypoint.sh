#!/bin/bash
set -e

echo "Aguardando PostgreSQL..."
until PGPASSWORD=$POSTGRES_PASSWORD pg_isready -h db -U loyalty -q 2>/dev/null; do
  sleep 1
done

echo "PostgreSQL disponível. Executando migrations..."
bundle exec rails db:create db:migrate

echo "Iniciando servidor..."
exec bundle exec rails server -b 0.0.0.0
