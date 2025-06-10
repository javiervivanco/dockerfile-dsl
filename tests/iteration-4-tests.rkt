#lang racket/base

(require rackunit
         "../dockerfile-dsl.rkt"
         "../private/dockerfile-validation.rkt")

(provide iteration-4-tests)

;; Tests para comandos de la Iteración 4
(define iteration-4-tests
  (test-suite "Tests de Iteración 4 - Funcionalidades Avanzadas"

    ;; Test de ENTRYPOINT shell form
    (test-case "ENTRYPOINT shell form"
      (define cmd (entrypoint "/app/entrypoint.sh"))
      (check-equal? (dockerfile-command-type cmd) 'entrypoint)
      (check-equal? (dockerfile-command-args cmd) '("/app/entrypoint.sh"))
      (check-false (assoc 'exec-form (dockerfile-command-options cmd))))

    ;; Test de ENTRYPOINT exec form
    (test-case "ENTRYPOINT exec form"
      (define cmd (entrypoint "docker-entrypoint.sh" "postgres"))
      (check-equal? (dockerfile-command-type cmd) 'entrypoint)
      (check-equal? (dockerfile-command-args cmd) '("docker-entrypoint.sh" "postgres"))
      (check-true (assoc 'exec-form (dockerfile-command-options cmd))))

    ;; Test de VOLUME simple
    (test-case "VOLUME simple"
      (define cmd (volume "/data"))
      (check-equal? (dockerfile-command-type cmd) 'volume)
      (check-equal? (dockerfile-command-args cmd) '("/data")))

    ;; Test de VOLUME múltiple
    (test-case "VOLUME múltiple"
      (define cmd (volume "/var/lib/mysql" "/var/log/mysql"))
      (check-equal? (dockerfile-command-type cmd) 'volume)
      (check-equal? (dockerfile-command-args cmd) '("/var/lib/mysql" "/var/log/mysql")))

    ;; Test de USER
    (test-case "USER básico"
      (define cmd (user "node"))
      (check-equal? (dockerfile-command-type cmd) 'user)
      (check-equal? (dockerfile-command-args cmd) '("node")))

    ;; Test de USER con UID:GID
    (test-case "USER con UID:GID"
      (define cmd (user "1000:1000"))
      (check-equal? (dockerfile-command-type cmd) 'user)
      (check-equal? (dockerfile-command-args cmd) '("1000:1000")))

    ;; Test de HEALTHCHECK
    (test-case "HEALTHCHECK básico"
      (define cmd (healthcheck "CMD curl -f http://localhost/ || exit 1"))
      (check-equal? (dockerfile-command-type cmd) 'healthcheck)
      (check-equal? (dockerfile-command-args cmd) '("CMD curl -f http://localhost/ || exit 1")))

    ;; Test de formateo de ENTRYPOINT exec form
    (test-case "Formateo de ENTRYPOINT exec form"
      (define df (docker-file
                   (from "alpine:latest")
                   (entrypoint "sh" "-c" "echo hello")))
      (define result (docker-file->string df))
      (check-true (regexp-match? #rx"ENTRYPOINT \\[\"sh\", \"-c\", \"echo hello\"\\]" result)))

    ;; Test de formateo de VOLUME
    (test-case "Formateo de VOLUME"
      (define df (docker-file
                   (from "postgres:13")
                   (volume "/var/lib/postgresql/data")))
      (define result (docker-file->string df))
      (check-true (regexp-match? #rx"VOLUME \\[\"/var/lib/postgresql/data\"\\]" result)))

    ;; Test de formateo de USER
    (test-case "Formateo de USER"
      (define df (docker-file
                   (from "node:18")
                   (user "node")))
      (define result (docker-file->string df))
      (check-true (regexp-match? #rx"USER node" result)))

    ;; Test de validación avanzada
    (test-case "Validación avanzada básica"
      (define df (docker-file
                   (from "ubuntu:latest")
                   (workdir "/app")
                   (healthcheck "CMD curl -f http://localhost/ || exit 1")))
      (check-true (validate-dockerfile-advanced df)))

    ;; Test de validación multi-stage
    (test-case "Validación multi-stage dependencies"
      (define df (docker-file
                   (from/as "golang:1.22" "builder")
                   (workdir "/build")
                   (copy "." ".")
                   (run "go build -o app .")
                   (from "alpine:latest")
                   (copy/from "builder" "/build/app" "/usr/local/bin/")))
      (check-true (validate-multistage-dependencies df)))

    ;; Test de aplicación completa con todos los comandos
    (test-case "Aplicación completa con comandos avanzados"
      (define df (docker-file
                   (from "node:18-alpine")
                   (label '("version" . "1.0") '("description" . "Complete app"))
                   (user "node")
                   (workdir "/app")
                   (copy "package*.json" "./")
                   (run "npm ci --only=production")
                   (copy "." ".")
                   (volume "/app/data")
                   (expose 3000)
                   (healthcheck "CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1")
                   (entrypoint "node" "server.js")))
      (define result (docker-file->string df))
      (check-true (validate-dockerfile-advanced df))
      (check-true (regexp-match? #rx"USER node" result))
      (check-true (regexp-match? #rx"VOLUME \\[\"/app/data\"\\]" result))
      (check-true (regexp-match? #rx"HEALTHCHECK" result))
      (check-true (regexp-match? #rx"ENTRYPOINT \\[\"node\", \"server.js\"\\]" result)))))

;; Ejecutar tests
(module+ test
  (require rackunit/text-ui)
  (run-tests iteration-4-tests))
