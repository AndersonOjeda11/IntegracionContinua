#!/usr/bin/env bash
# Prueba de ida y vuelta entre los contenedores:
# la app guarda una operacion en la base de datos (servicio "db") y luego la vuelve a leer.
# Uso:  bash scripts/prueba_comunicacion.sh [URL]    (por defecto http://localhost:5000)
set -euo pipefail

URL="${1:-http://localhost:5000}"

echo "== 1. La app resuelve el servicio 'db' por su nombre dentro de la red de Docker"
docker compose exec -T app getent hosts db

echo
echo "== 2. Salud de la app y conexion con la base de datos"
curl -fsS "$URL/salud"
echo

echo
echo "== 3. Guardar una operacion (app -> db)"
respuesta=$(curl -fsS -X POST "$URL/operaciones" \
  -H "Content-Type: application/json" \
  -d '{"operacion": "multiplicar", "a": 6, "b": 7}')
echo "$respuesta"
id=$(echo "$respuesta" | sed -E 's/.*"id": ?([0-9]+).*/\1/')

echo
echo "== 4. Leer la operacion $id desde la base de datos (db -> app)"
leida=$(curl -fsS "$URL/operaciones/$id")
echo "$leida"

echo
echo "== 5. El dato esta guardado dentro del contenedor de PostgreSQL"
docker compose exec -T db sh -c \
  'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT id, operacion, a, b, resultado FROM operaciones WHERE id = '"$id"';"'

if echo "$leida" | grep -q '"resultado": \?42'; then
  echo "OK: la operacion guardada (6 x 7 = 42) se leyo de vuelta desde la base de datos."
else
  echo "ERROR: el dato leido no coincide con el guardado." >&2
  exit 1
fi
