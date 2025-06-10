#lang racket/base

(require "../dockerfile-dsl.rkt")

;; Ejemplo demostrativo final que usa todas las características de las 3 iteraciones
(define comprehensive-example
  (docker-file
    ;; === ITERACIÓN 1: Comandos básicos ===
    (from "ubuntu:22.04")
    (workdir "/app")

    ;; === ITERACIÓN 2: Comandos extendidos ===
    (env '("DEBIAN_FRONTEND" . "noninteractive")
         '("APP_ENV" . "production"))

    (run "apt-get update"
         "apt-get install -y python3 python3-pip curl"
         "rm -rf /var/lib/apt/lists/*")

    ;; === ITERACIÓN 3: Comandos con opciones ===
    (arg "VERSION" "1.0.0")
    (label '("version" . "1.0.0")
           '("maintainer" . "team@company.com")
           '("description" . "Demo application"))

    (copy "requirements.txt" "./")
    (run "pip3 install -r requirements.txt")

    (copy "app.py" "./")
    (expose 5000)
    (cmd "python3" "app.py")))

;; Ejemplo multi-stage más simple
(define simple-multistage
  (docker-file
    ;; Build stage
    (from/as "python:3.11-slim" "builder")
    (workdir "/build")
    (copy "requirements.txt" "./")
    (run "pip install --user -r requirements.txt")

    ;; Runtime stage
    (from "python:3.11-slim")
    (copy/from "builder" "/root/.local" "/root/.local")
    (workdir "/app")
    (copy "." "./")
    (cmd "python" "app.py")))

(displayln "=== DEMO COMPLETO - ITERACIONES 1, 2 y 3 ===")
(displayln (docker-file->string comprehensive-example))
(displayln "")
(displayln "=== MULTI-STAGE BUILD SIMPLE ===")
(displayln (docker-file->string simple-multistage))
(displayln "")
(displayln "=== ESTADO DEL PROYECTO ===")
(displayln "🎉 Las primeras 3 iteraciones del DSL de Dockerfile están COMPLETAS!")
(displayln "")
(displayln "Funcionalidades implementadas:")
(displayln "- ✅ Comandos básicos (FROM, WORKDIR, COPY, RUN)")
(displayln "- ✅ Comandos extendidos (ENV, EXPOSE, CMD, ADD)")
(displayln "- ✅ Opciones avanzadas (--from, --mount, AS)")
(displayln "- ✅ Multi-stage builds")
(displayln "- ✅ Representación intermedia (IR)")
(displayln "- ✅ Sistema de formateo")
(displayln "- ✅ Suite de tests")
(displayln "- ✅ Ejemplos demostrativos")
(displayln "")
(displayln "El DSL está listo para las siguientes iteraciones! 🚀")
