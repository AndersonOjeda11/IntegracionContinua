#!/usr/bin/env bash
# Prueba de ida y vuelta entre los contenedores:
# la app guarda una operacion en la base de datos (servicio "db") y luego la vuelve a leer.
# Las peticiones se hacen desde dentro del contenedor de la app, asi la prueba no depende de
# puertos publicados y funciona igual en el equipo local, en Jenkins y en GitHub Actions.
# Uso:  bash scripts/prueba_comunicacion.sh
# Si cualquier paso falla, el script termina con error (y el build de Jenkins falla).
set -euo pipefail

# Peticion HTTP a la API: api METODO RUTA [CUERPO_JSON]
api() {
  docker compose exec -T app python - "$1" "$2" "${3:-}" <<'PY'
import sys
import urllib.request

metodo, ruta, cuerpo = sys.argv[1], sys.argv[2], sys.argv[3]
peticion = urllib.request.Request(
    "http://localhost:5000" + ruta,
    data=cuerpo.encode() if cuerpo else None,
    method=metodo,
    headers={"Content-Type": "application/json"},
)
with urllib.request.urlopen(peticion, timeout=10) as respuesta:
    print(respuesta.read().decode().strip())
PY
}

echo "== 1. La app resuelve el servicio 'db' por su nombre dentro de la red de Docker"
docker compose exec -T app getent hosts db

echo
echo "== 2. Salud de la app y conexion con la base de datos"
api GET /salud

echo
echo "== 3. Guardar una operacion (app -> db)"
respuesta=$(api POST /operaciones '{"operacion": "multiplicar", "a": 6, "b": 7}')
echo "$respuesta"
id=$(echo "$respuesta" | sed -E 's/.*"id": ?([0-9]+).*/\1/')

echo
echo "== 4. Leer la operacion $id desde la base de datos (db -> app)"
leida=$(api GET "/operaciones/$id")
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
