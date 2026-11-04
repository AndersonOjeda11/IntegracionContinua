# calculadora-ci

Proyecto de la *Guía de ejercicios: Manejo de repositorios*. Es una calculadora en Python con
pruebas en pytest, configuración por ambiente y un pipeline de integración continua en GitHub
Actions.

## Cómo ejecutarlo

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
