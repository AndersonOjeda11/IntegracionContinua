"""API de la calculadora: hace operaciones y las guarda y lee en PostgreSQL."""

import os

import psycopg
from flask import Flask, jsonify, request
from psycopg.rows import dict_row

from calculadora import dividir, multiplicar, potencia, restar, sumar

OPERACIONES = {
    "sumar": sumar,
    "restar": restar,
    "multiplicar": multiplicar,
    "dividir": dividir,
    "potencia": potencia,
}

app = Flask(__name__)


def conectar():
    # DB_HOST es el nombre del servicio en docker-compose ("db"), no localhost ni una IP.
    # Las credenciales llegan por variables de entorno desde el archivo .env.
    return psycopg.connect(
        host=os.environ["DB_HOST"],
        port=os.environ.get("DB_PORT", "5432"),
        dbname=os.environ["POSTGRES_DB"],
        user=os.environ["POSTGRES_USER"],
        password=os.environ["POSTGRES_PASSWORD"],
        connect_timeout=5,
        row_factory=dict_row,
    )


def a_json(fila):
    fila["creado_en"] = fila["creado_en"].isoformat()
    return fila


@app.get("/")
def inicio():
    return jsonify(
        servicio="calculadora-app",
        operaciones=sorted(OPERACIONES),
        rutas=["GET /salud", "POST /operaciones", "GET /operaciones", "GET /operaciones/<id>"],
    )


@app.get("/salud")
def salud():
    with conectar() as conexion:
        fila = conexion.execute(
            "SELECT current_database() AS base_datos, inet_server_addr()::text AS ip_db, "
            "split_part(version(), ' ', 2) AS version_postgres"
        ).fetchone()
    return jsonify(estado="ok", db_host=os.environ["DB_HOST"], **fila)


@app.post("/operaciones")
def crear_operacion():
    datos = request.get_json(silent=True) or {}
    nombre = datos.get("operacion")
    if nombre not in OPERACIONES:
        return jsonify(error=f"Operacion no valida. Use una de: {', '.join(sorted(OPERACIONES))}"), 400
    try:
        a, b = float(datos["a"]), float(datos["b"])
    except (KeyError, TypeError, ValueError):
        return jsonify(error="Los campos 'a' y 'b' deben ser numeros"), 400
    try:
        resultado = OPERACIONES[nombre](a, b)
    except (ZeroDivisionError, OverflowError) as error:
        return jsonify(error=str(error)), 400

    with conectar() as conexion:
        fila = conexion.execute(
            "INSERT INTO operaciones (operacion, a, b, resultado) VALUES (%s, %s, %s, %s) "
            "RETURNING id, operacion, a, b, resultado, creado_en",
            (nombre, a, b, resultado),
        ).fetchone()
    return jsonify(a_json(fila)), 201


@app.get("/operaciones")
def listar_operaciones():
    with conectar() as conexion:
        filas = conexion.execute(
            "SELECT id, operacion, a, b, resultado, creado_en FROM operaciones ORDER BY id DESC LIMIT 20"
        ).fetchall()
    return jsonify([a_json(fila) for fila in filas])


@app.get("/operaciones/<int:id_operacion>")
def leer_operacion(id_operacion):
    with conectar() as conexion:
        fila = conexion.execute(
            "SELECT id, operacion, a, b, resultado, creado_en FROM operaciones WHERE id = %s",
            (id_operacion,),
        ).fetchone()
    if fila is None:
        return jsonify(error="Operacion no encontrada"), 404
    return jsonify(a_json(fila))
