# Contenedor 2: PostgreSQL con el script que crea la tabla "operaciones".
# Se construye con:  docker build -t calculadora-db:1.0 db

# Imagen oficial de PostgreSQL con version fija (no "latest").
FROM postgres:17.11-alpine

# PostgreSQL ejecuta los scripts de esta carpeta la primera vez que arranca (volumen vacio).
COPY init.sql /docker-entrypoint-initdb.d/init.sql

EXPOSE 5432
