#lang racket/base

(require "../dockerfile-dsl.rkt")

;; Ejemplo básico de uso del DSL
(define basic-dockerfile
  (docker-file
    (from "ubuntu:latest")
    (workdir "/app")
    (copy "package.json" "./")
    (copy "src/" "./src/")
    (run "apt-get update")
    (run "apt-get install -y nodejs npm")
    (run "npm install")))

;; Generar el string del Dockerfile
(define dockerfile-string (docker-file->string basic-dockerfile))

;; Mostrar el resultado
(displayln "=== Dockerfile generado ===")
(displayln dockerfile-string)
(displayln "")
(displayln "=== Estructura IR ===")
(displayln (dockerfile->ir-list basic-dockerfile))
(displayln "")
(displayln "=== Validación ===")
(displayln (format "Estructura válida: ~a" (validate-dockerfile-structure basic-dockerfile)))
