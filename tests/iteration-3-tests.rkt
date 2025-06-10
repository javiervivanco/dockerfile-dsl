#lang racket/base

(require rackunit
         "../dockerfile-dsl.rkt")

(provide iteration-3-tests)

;; Tests para comandos de la Iteración 3
(define iteration-3-tests
  (test-suite "Tests de Iteración 3 - Opciones y Flags Avanzados"

    ;; Test de COPY con --from
    (test-case "COPY con --from"
      (define cmd (copy/from "builder" "/app/bin" "/usr/local/bin/"))
      (check-equal? (dockerfile-command-type cmd) 'copy)
      (check-equal? (dockerfile-command-args cmd) '("/app/bin" "/usr/local/bin/"))
      (check-equal? (cdr (assoc 'from (dockerfile-command-options cmd))) "builder"))

    ;; Test de RUN con --mount
    (test-case "RUN con --mount"
      (define mount-spec '((type . "bind") (source . ".") (target . "/app")))
      (define cmd (run/mount mount-spec "go build"))
      (check-equal? (dockerfile-command-type cmd) 'run)
      (check-equal? (dockerfile-command-args cmd) '("go build"))
      (check-equal? (cdr (assoc 'mount (dockerfile-command-options cmd))) mount-spec))

    ;; Test de ARG sin valor por defecto
    (test-case "ARG sin valor por defecto"
      (define cmd (arg "VERSION"))
      (check-equal? (dockerfile-command-type cmd) 'arg)
      (check-equal? (dockerfile-command-args cmd) '("VERSION")))

    ;; Test de ARG con valor por defecto
    (test-case "ARG con valor por defecto"
      (define cmd (arg "BUILD_DATE" "2024-01-01"))
      (check-equal? (dockerfile-command-type cmd) 'arg)
      (check-equal? (dockerfile-command-args cmd) '("BUILD_DATE=2024-01-01")))

    ;; Test de LABEL
    (test-case "LABEL con múltiples etiquetas"
      (define cmd (label '("version" . "1.0") '("maintainer" . "dev@example.com")))
      (check-equal? (dockerfile-command-type cmd) 'label)
      (check-equal? (dockerfile-command-args cmd) '("version=\"1.0\"" "maintainer=\"dev@example.com\"")))

    ;; Test de formateo de COPY --from
    (test-case "Formateo de COPY --from"
      (define df (docker-file
                   (from/as "golang:1.22" "builder")
                   (copy/from "builder" "/app/myapp" "/usr/local/bin/")))
      (define result (docker-file->string df))
      (check-true (regexp-match? #rx"COPY --from=builder /app/myapp /usr/local/bin/" result)))

    ;; Test de formateo de RUN --mount
    (test-case "Formateo de RUN --mount"
      (define df (docker-file
                   (from "golang:1.22")
                   (run/mount '((type . "bind") (source . ".") (target . "/app")) "go build")))
      (define result (docker-file->string df))
      (check-true (regexp-match? #rx"RUN --mount=type=bind,source=\\.,target=/app go build" result)))

    ;; Test de formateo de ARG
    (test-case "Formateo de ARG"
      (define df (docker-file
                   (arg "VERSION" "1.0")
                   (from "ubuntu:latest")))
      (define result (docker-file->string df))
      (check-true (regexp-match? #rx"ARG VERSION=1.0" result)))

    ;; Test de formateo de LABEL
    (test-case "Formateo de LABEL"
      (define df (docker-file
                   (from "ubuntu:latest")
                   (label '("version" . "1.0") '("description" . "My app"))))
      (define result (docker-file->string df))
      (check-true (regexp-match? #rx"LABEL version=\"1.0\" description=\"My app\"" result)))

    ;; Test completo multi-stage con opciones
    (test-case "Multi-stage build completo"
      (define df (docker-file
                   (arg "GO_VERSION" "1.22")
                   (from/as "golang:1.22" "builder")
                   (workdir "/build")
                   (copy "go.mod" "./")
                   (copy "go.sum" "./")
                   (run/mount '((type . "cache") (target . "/go/pkg/mod")) "go mod download")
                   (copy "." ".")
                   (run "go build -o app ./cmd/main")

                   (from "alpine:latest")
                   (label '("version" . "1.0") '("maintainer" . "dev@company.com"))
                   (copy/from "builder" "/build/app" "/usr/local/bin/app")
                   (cmd "app")))
      (define result (docker-file->string df))
      (check-true (regexp-match? #rx"ARG GO_VERSION=1.22" result))
      (check-true (regexp-match? #rx"FROM golang:1.22 AS builder" result))
      (check-true (regexp-match? #rx"RUN --mount=type=cache,target=/go/pkg/mod go mod download" result))
      (check-true (regexp-match? #rx"COPY --from=builder /build/app /usr/local/bin/app" result)))))

;; Ejecutar tests
(module+ test
  (require rackunit/text-ui)
  (run-tests iteration-3-tests))
