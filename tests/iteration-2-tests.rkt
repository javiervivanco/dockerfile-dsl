#lang racket/base

(require rackunit
         "../dockerfile-dsl.rkt")

(provide iteration-2-tests)

;; Tests para comandos de la Iteración 2
(define iteration-2-tests
  (test-suite "Tests de Iteración 2 - Comandos Extendidos"

    ;; Test de RUN con múltiples comandos
    (test-case "RUN con múltiples comandos"
      (define run-cmd (run "apt-get update" "apt-get install -y curl" "apt-get clean"))
      (check-equal? (dockerfile-command-type run-cmd) 'run)
      (check-equal? (dockerfile-command-args run-cmd) '("apt-get update && apt-get install -y curl && apt-get clean")))

    ;; Test de ENV
    (test-case "ENV con múltiples variables"
      (define env-cmd (env '("DEBUG" . "true") '("PORT" . "8080")))
      (check-equal? (dockerfile-command-type env-cmd) 'env)
      (check-equal? (dockerfile-command-args env-cmd) '("DEBUG=\"true\"" "PORT=\"8080\"")))

    ;; Test de EXPOSE
    (test-case "EXPOSE con múltiples puertos"
      (define expose-cmd (expose 80 8080 8443))
      (check-equal? (dockerfile-command-type expose-cmd) 'expose)
      (check-equal? (dockerfile-command-args expose-cmd) '("80" "8080" "8443")))

    ;; Test de CMD shell form
    (test-case "CMD shell form"
      (define cmd-shell (cmd "npm start"))
      (check-equal? (dockerfile-command-type cmd-shell) 'cmd)
      (check-equal? (dockerfile-command-args cmd-shell) '("npm start"))
      (check-false (assoc 'exec-form (dockerfile-command-options cmd-shell))))

    ;; Test de CMD exec form
    (test-case "CMD exec form"
      (define cmd-exec (cmd "node" "server.js"))
      (check-equal? (dockerfile-command-type cmd-exec) 'cmd)
      (check-equal? (dockerfile-command-args cmd-exec) '("node" "server.js"))
      (check-not-false (assoc 'exec-form (dockerfile-command-options cmd-exec))))

    ;; Test de ADD
    (test-case "ADD básico"
      (define add-cmd (add "file.tar.gz" "/app/"))
      (check-equal? (dockerfile-command-type add-cmd) 'add)
      (check-equal? (dockerfile-command-args add-cmd) '("file.tar.gz" "/app/")))    ;; Test de formateo de ENV
    (test-case "Formateo de ENV"
      (define df (docker-file
                   (from "ubuntu:latest")
                   (env '("NODE_ENV" . "production") '("PORT" . "3000"))))
      (define result (docker-file->string df))
      (check-true (regexp-match? #rx"ENV NODE_ENV=\"production\" PORT=\"3000\"" result)))

    ;; Test de formateo de CMD exec form
    (test-case "Formateo de CMD exec form"
      (define df (docker-file
                   (from "node:18")
                   (cmd "node" "server.js")))
      (define result (docker-file->string df))
      (check-true (regexp-match? #rx"CMD \\[\"node\", \"server.js\"\\]" result)))

    ;; Test de formateo de EXPOSE
    (test-case "Formateo de EXPOSE"
      (define df (docker-file
                   (from "nginx")
                   (expose 80 443)))
      (define result (docker-file->string df))
      (check-true (regexp-match? #rx"EXPOSE 80 443" result)))

    ;; Test completo con todos los comandos nuevos
    (test-case "Dockerfile completo con comandos Iteración 2"
      (define df (docker-file
                   (from "node:18-alpine")
                   (workdir "/app")
                   (env '("NODE_ENV" . "production"))
                   (copy "package*.json" "./")
                   (run "npm ci" "npm cache clean --force")
                   (copy "." ".")
                   (expose 3000)
                   (cmd "node" "index.js")))
      (define result (docker-file->string df))
      (check-true (regexp-match? #rx"FROM node:18-alpine" result))
      (check-true (regexp-match? #rx"ENV NODE_ENV=\"production\"" result))
      (check-true (regexp-match? #rx"RUN npm ci && npm cache clean --force" result))
      (check-true (regexp-match? #rx"EXPOSE 3000" result))
      (check-true (regexp-match? #rx"CMD \\[\"node\", \"index.js\"\\]" result)))))

;; Ejecutar tests
(module+ test
  (require rackunit/text-ui)
  (run-tests iteration-2-tests))
