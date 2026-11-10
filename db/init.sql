-- Contenedor 2: PostgreSQL. Este script corre solo la primera vez, cuando el volumen esta vacio.
CREATE TABLE IF NOT EXISTS operaciones (
    id         SERIAL PRIMARY KEY,
    operacion  VARCHAR(20)      NOT NULL,
    a          DOUBLE PRECISION NOT NULL,
    b          DOUBLE PRECISION NOT NULL,
    resultado  DOUBLE PRECISION NOT NULL,
    creado_en  TIMESTAMPTZ      NOT NULL DEFAULT now()
);
