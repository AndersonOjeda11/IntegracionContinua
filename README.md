# calculadora-ci

Calculadora en Python con pruebas en pytest, configuración por ambiente, un pipeline de
integración continua en GitHub Actions y, desde la Entrega del proyecto 1, dos contenedores
Docker que se comunican entre sí.

## Proyecto 1: Docker con dos contenedores comunicados

```
 Navegador / curl
       │  http://localhost:5000
       ▼
┌──────────────────────── red_calculadora (bridge) ────────────────────────┐
│                                                                          │
│  ┌──────────────────────┐   host "db", puerto 5432   ┌─────────────────┐ │
│  │ app (calculadora-app)│ ─────────────────────────▶ │ db (PostgreSQL) │ │
│  │ Flask + Gunicorn     │ ◀───────────────────────── │ postgres:17.11  │ │
│  │ python:3.13.18-slim  │   guarda y lee operaciones │ volumen datos_db│ │
│  └──────────────────────┘                            └─────────────────┘ │
└──────────────────────────────────────────────────────────────────────────┘
```

| Servicio | Papel | Imagen | Puerto |
| --- | --- | --- | --- |
| `app` | API de la calculadora: hace la operación y la guarda en la base de datos | `calculadora-app:1.0` (Dockerfile propio sobre `python:3.13.18-slim`) | `5000` publicado en el equipo |
| `db` | Base de datos que guarda el historial de operaciones | `postgres:17.11-alpine` | `5432`, solo dentro de la red |

La app se conecta a la base de datos con el **nombre del servicio** (`DB_HOST: db`), que Docker
resuelve dentro de la red `red_calculadora`. No usa `localhost` ni una IP fija.

### Estructura

```
.
├── app/
│   ├── Dockerfile          # contenedor 1: la aplicación
│   ├── main.py             # API Flask (rutas /salud y /operaciones)
│   └── requirements.txt    # dependencias con versión fija
├── db/
│   └── init.sql            # contenedor 2: crea la tabla "operaciones"
├── scripts/
│   └── prueba_comunicacion.sh   # prueba de ida y vuelta app <-> db
├── .github/workflows/
│   ├── ci.yml              # pruebas con pytest
│   └── docker.yml          # construye las imágenes y prueba la comunicación
├── docker-compose.yml      # orquesta los dos servicios
├── .dockerignore
├── .env.example            # plantilla de variables (el .env real no se sube)
├── calculadora.py          # lógica que reutiliza la API
└── config.py
```

### Comandos para levantar los contenedores

1. Cree el archivo `.env` a partir de la plantilla y cambie la contraseña:

   ```bash
   cp .env.example .env
   ```

2. Construya la imagen de la aplicación (opcional, `compose up --build` también la construye):

   ```bash
   docker build -f app/Dockerfile -t calculadora-app:1.0 .
   ```

3. Levante los dos contenedores:

   ```bash
   docker compose up -d --build
   ```

4. Revise que estén corriendo y en qué red están:

   ```bash
   docker ps
   docker network inspect red_calculadora
   ```

5. Pruebe la comunicación (guarda una operación y la vuelve a leer desde la base de datos):

   ```bash
   bash scripts/prueba_comunicacion.sh
   ```

   O a mano:

   ```bash
   curl http://localhost:5000/salud
   curl -X POST http://localhost:5000/operaciones -H "Content-Type: application/json" -d '{"operacion": "sumar", "a": 2, "b": 3}'
   curl http://localhost:5000/operaciones/1
   ```

6. Apague todo (agregue `-v` para borrar también el volumen con los datos):

   ```bash
   docker compose down
   ```

### Rutas de la API

| Método | Ruta | Qué hace |
| --- | --- | --- |
| `GET` | `/salud` | Consulta la base de datos y responde con el host usado (`db`), su IP en la red y la versión de PostgreSQL |
| `POST` | `/operaciones` | Recibe `{"operacion", "a", "b"}`, calcula el resultado y lo guarda en la base de datos |
| `GET` | `/operaciones` | Lista las últimas 20 operaciones guardadas |
| `GET` | `/operaciones/<id>` | Lee una operación guardada |

Operaciones disponibles: `sumar`, `restar`, `multiplicar`, `dividir` y `potencia`.

### Buenas prácticas aplicadas

- Imágenes base oficiales con versión fija: `python:3.13.18-slim` y `postgres:17.11-alpine`.
- Contraseñas solo en `.env`, que está en `.gitignore`. El repositorio solo tiene `.env.example`.
- Ningún secreto en el código: la app lee las credenciales de variables de entorno.
- `.dockerignore` en modo lista blanca: a la imagen solo entran `calculadora.py`, `app/main.py` y
  `app/requirements.txt`.
- La app corre con un usuario sin privilegios (`appuser`) y tiene `HEALTHCHECK`.
- La base de datos no publica su puerto en el equipo anfitrión; solo es accesible dentro de la red.
- Los datos persisten en el volumen `calculadora_datos_db` aunque se borren los contenedores.

### Integración continua

El workflow `.github/workflows/docker.yml` corre en cada push y pull request: valida el
`docker-compose.yml`, construye las imágenes, levanta los contenedores y ejecuta
`scripts/prueba_comunicacion.sh`. Si la app no logra guardar y leer el dato en la base de datos,
el check queda en rojo.

## Guía de ejercicios: cómo ejecutar las pruebas

```bash
python -m pip install pytest
python -m pytest
```

Para elegir el ambiente se usa la variable `APP_ENV` (`desarrollo`, `pruebas` o `produccion`):

```bash
APP_ENV=pruebas python -c "from config import cargar_config; print(cargar_config())"
```

## Respuestas de la guía

### Ejercicio 1: Primer repositorio

**¿Qué diferencia hay entre el directorio de trabajo, el área de preparación y el repositorio?**

El directorio de trabajo son los archivos tal como los estoy editando. El área de preparación
(*staging*) guarda los cambios que elegí con `git add` para el próximo commit. El repositorio
(la carpeta `.git`) guarda los commits ya confirmados, es decir, el historial.

### Ejercicio 2: Ramas y conflicto

**¿Por qué Git no eligió una de las dos versiones por su cuenta?**

Porque las dos ramas cambiaron la misma zona de `calculadora.py` y Git no puede saber cuál era
la intención correcta: quedarse con una, con la otra o con las dos. Por eso se detiene y deja que
una persona decida. En este caso se conservaron las dos funciones (`dividir` y `multiplicar`).

### Ejercicio 3: Recuperar una versión

**¿Por qué se prefiere `git revert` a borrar commits cuando otras personas ya tienen el historial?**

`git revert` crea un commit nuevo que deshace el cambio, sin reescribir los commits anteriores.
Así, quien ya descargó el historial puede hacer `git pull` sin conflictos. Borrar commits con
`reset` y `push --force` cambia el historial que otros ya tienen y les rompe sus copias.

### Ejercicio 4: Remoto y pull request

**Si GitHub se cae hoy, ¿qué copias del proyecto siguen existiendo y qué tendría que hacer el equipo?**

Cada copia clonada tiene el proyecto completo con todo su historial, así que el proyecto sigue
existiendo en el computador de cada integrante. El equipo puede publicar una de esas copias en
otro servidor (otro GitHub, GitLab, un servidor propio), cambiar el `origin` con
`git remote set-url` y seguir trabajando. Lo que no está en el clon, como los issues, los pull
requests y sus comentarios, sí se perdería.

### Ejercicio 5: Ambientes

| Situación | Ambiente |
| --- | --- |
| Una desarrolladora prueba una función nueva con datos ficticios | Desarrollo |
| El equipo QA ejecuta sus pruebas en un servidor compartido | Pruebas |
| El cliente y usuarios invitados evalúan una versión antes del lanzamiento | Entorno intermedio (*staging*) |
| Un desarrollador copia datos reales de clientes a su portátil | Mala práctica: expone datos de los usuarios |
| Alguien edita un archivo directamente en el servidor que atiende a los usuarios | Mala práctica: se salta el control de versiones y las pruebas |

### Ejercicio 6: Pipeline de integración continua

**¿Qué parte de lo que hizo a mano en el ejercicio 1 ahora hace el pipeline?**

Ejecutar las pruebas (`python -m pytest`). Ahora GitHub Actions las corre solo en cada push a
`main` y en cada pull request, y muestra el resultado (check verde o rojo) en el pull request
antes de fusionar. Con la matriz del reto, además se prueba en Python 3.12 y 3.13.
