#lang racket/base

(require rackunit
         "../dockerfile-dsl.rkt")

(provide basic-tests)

;; Test de comandos básicos individuales
(define basic-tests
  (test-suite "Tests básicos del DSL de Dockerfile"

    ;; Test del comando FROM
    (test-case "FROM básico"
      (define cmd (from "ubuntu:latest"))
      (check-equal? (dockerfile-command-type cmd) 'from)
      (check-equal? (dockerfile-command-args cmd) '("ubuntu:latest")))

    (test-case "FROM con tag separado"
      (define cmd (from "node" "18-alpine"))
      (check-equal? (dockerfile-command-type cmd) 'from)
      (check-equal? (dockerfile-command-args cmd) '("node:18-alpine")))

    ;; Test del comando WORKDIR
    (test-case "WORKDIR básico"
      (define cmd (workdir "/app"))
      (check-equal? (dockerfile-command-type cmd) 'workdir)
      (check-equal? (dockerfile-command-args cmd) '("/app")))

    ;; Test del comando COPY
    (test-case "COPY básico"
      (define cmd (copy "src/" "dest/"))
      (check-equal? (dockerfile-command-type cmd) 'copy)
      (check-equal? (dockerfile-command-args cmd) '("src/" "dest/")))

    ;; Test del comando RUN
    (test-case "RUN básico"
      (define cmd (run "apt-get update"))
      (check-equal? (dockerfile-command-type cmd) 'run)
      (check-equal? (dockerfile-command-args cmd) '("apt-get update")))

    ;; Test del constructor principal
    (test-case "docker-file constructor"
      (define df (docker-file
                   (from "ubuntu:latest")
                   (workdir "/app")
                   (copy "." ".")
                   (run "apt-get update")))
      (check-equal? (length (dockerfile-commands df)) 4)
      (check-true (validate-dockerfile-structure df)))

    ;; Test de conversión a string
    (test-case "docker-file->string básico"
      (define df (docker-file
                   (from "ubuntu:latest")
                   (workdir "/app")))
      (define result (docker-file->string df))
      (check-equal? result "FROM ubuntu:latest\nWORKDIR /app"))

    ;; Test completo con todos los comandos básicos
    (test-case "Dockerfile completo básico"
      (define df (docker-file
                   (from "ubuntu:latest")
                   (workdir "/app")
                   (copy "package.json" "./")
                   (run "apt-get update")))
      (define result (docker-file->string df))
      (define expected "FROM ubuntu:latest\nWORKDIR /app\nCOPY package.json ./\nRUN apt-get update")
      (check-equal? result expected))))

;; Ejecutar tests
(module+ test
  (require rackunit/text-ui)
  (run-tests basic-tests))
