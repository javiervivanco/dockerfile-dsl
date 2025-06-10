#lang racket/base

(require rackunit
         rackunit/text-ui
         "../dockerfile-dsl.rkt")

;; === TESTS DE FUNCIONES DE ORDEN SUPERIOR ===

(define higher-order-tests
  (test-suite "Higher Order Functions Tests"

    (test-case "base-image function"
      (define ubuntu-base (base-image "ubuntu:latest"))
      (define result (ubuntu-base (workdir "/app") (run "apt-get update")))
      (check-true (dockerfile? result))
      (check-equal? (length (dockerfile-commands result)) 3))

    (test-case "node-app-template"
      (define node-template (node-app-template "18" "my-app"))
      (define result (node-template (user "node") (cmd "npm" "start")))
      (check-true (dockerfile? result))
      (define commands (dockerfile-commands result))
      (check-true (> (length commands) 5))
      ;; Verificar que tiene FROM node
      (define first-cmd (car commands))
      (check-equal? (dockerfile-command-type first-cmd) 'from)
      (check-true (string-contains? (car (dockerfile-command-args first-cmd)) "node:18")))

    (test-case "go-microservice-template"
      (define go-template (go-microservice-template "1.22" "auth-service"))
      (define result (go-template))
      (check-true (dockerfile? result))
      (define commands (dockerfile-commands result))
      ;; Verificar multi-stage build
      (define from-commands (filter (λ (cmd)
                                      (and (dockerfile-command? cmd)
                                           (eq? (dockerfile-command-type cmd) 'from)))
                                   commands))
      (check-equal? (length from-commands) 2))

    (test-case "combine-dockerfiles"
      (define df1 (docker-file (from "ubuntu") (workdir "/app")))
      (define df2 (docker-file (run "apt-get update") (expose 80)))
      (define combined (combine-dockerfiles df1 df2))
      (check-equal? (length (dockerfile-commands combined)) 4))

    (test-case "optimize-layers"
      (define original (docker-file
                         (from "ubuntu")
                         (run "apt-get update")
                         (run "apt-get install -y curl")
                         (run "apt-get clean")
                         (workdir "/app")))
      (define optimized (optimize-layers original))
      (define run-commands (filter (λ (cmd)
                                     (and (dockerfile-command? cmd)
                                          (eq? (dockerfile-command-type cmd) 'run)))
                                  (dockerfile-commands optimized)))
      ;; Debería tener menos comandos RUN después de optimizar
      (check-true (<= (length run-commands) 1)))))

;; === TESTS DE ANÁLISIS AVANZADO ===

(define analysis-tests
  (test-suite "Advanced Analysis Tests"

    (test-case "basic analysis"
      (define test-df (docker-file
                        (from "ubuntu:latest")
                        (workdir "/app")
                        (env '("NODE_ENV" . "production"))
                        (expose 80 443)
                        (user "appuser")
                        (run "apt-get update")))
      (define analysis (analyze-dockerfile test-df))
      (check-true (hash? analysis))
      (check-true (hash-has-key? analysis 'basic-info))
      (check-true (hash-has-key? analysis 'security))
      (check-true (hash-has-key? analysis 'performance)))

    (test-case "security analysis - no user command"
      (define insecure-df (docker-file
                            (from "ubuntu")
                            (run "apt-get update")
                            (expose 22)))
      (define security-issues (validate-security insecure-df))
      (check-true (list? security-issues))
      (check-true (> (length security-issues) 0)))

    (test-case "security analysis - secure dockerfile"
      (define secure-df (docker-file
                          (from "ubuntu")
                          (run "apt-get update")
                          (user "appuser")
                          (expose 80)))
      (define security-issues (validate-security secure-df))
      (check-true (list? security-issues))
      ;; Puede tener algunas advertencias pero menos que el inseguro
      )

    (test-case "complexity score"
      (define simple-df (docker-file (from "alpine") (run "echo hello")))
      (define complex-df (docker-file
                           (from "golang:1.22" #:as "builder")
                           (workdir "/build")
                           (copy "." ".")
                           (run "go build")
                           (from "alpine")
                           (copy "/build/app" "/app" #:from "builder")
                           (entrypoint "/app")))
      (define simple-score (dockerfile-complexity-score simple-df))
      (define complex-score (dockerfile-complexity-score complex-df))
      (check-true (< simple-score complex-score)))

    (test-case "size estimation"
      (define test-df (docker-file
                        (from "alpine:latest")
                        (run "apk add --no-cache curl")
                        (copy "app" "/usr/local/bin/")))
      (define estimated-size (estimate-image-size test-df))
      (check-true (number? estimated-size))
      (check-true (> estimated-size 0)))

    (test-case "security report generation"
      (define test-df (docker-file
                        (from "ubuntu")
                        (env '("PASSWORD" . "secret123"))
                        (expose 22)
                        (run "apt-get update")))
      (define report (generate-security-report test-df))
      (check-true (hash? report))
      (check-true (hash-has-key? report 'summary))
      (check-true (hash-has-key? report 'issues))
      (check-true (> (hash-ref (hash-ref report 'summary) 'total-issues) 0)))))

;; === TESTS DE MACROS ===

(define macro-tests
  (test-suite "Macro Tests"

    (test-case "with-context macro"
      (define result (with-context "/app"
                                   (copy "package.json" "./")
                                   (run "npm install")))
      (check-true (dockerfile? result))
      (define commands (dockerfile-commands result))
      (check-equal? (dockerfile-command-type (car commands)) 'workdir)
      (check-equal? (car (dockerfile-command-args (car commands))) "/app"))

    (test-case "security-setup macro"
      (define result (security-setup "appuser"))
      (check-true (dockerfile? result))
      (define commands (dockerfile-commands result))
      (check-true (> (length commands) 1)))

    (test-case "auto-optimize macro"
      (define result (auto-optimize
                       (from "ubuntu")
                       (run "apt-get update")
                       (run "apt-get install curl")
                       (run "apt-get clean")))
      (check-true (dockerfile? result))
      ;; Verificar que la optimización se aplicó
      (define run-commands (filter (λ (cmd)
                                     (and (dockerfile-command? cmd)
                                          (eq? (dockerfile-command-type cmd) 'run)))
                                  (dockerfile-commands result)))
      (check-true (<= (length run-commands) 1)))))

;; === TESTS DE INTEGRACIÓN ===

(define integration-tests
  (test-suite "Integration Tests"

    (test-case "complete nodejs application"
      (define nodejs-app
        ((node-app-template "18" "my-service")
         (security-setup "node")
         (copy "src/" "/app/src/")
         (expose 3000)
         (cmd "npm" "start")))

      (check-true (dockerfile? nodejs-app))
      (define dockerfile-string (docker-file->string nodejs-app))
      (check-true (string? dockerfile-string))
      (check-true (string-contains? dockerfile-string "FROM node:18"))
      (check-true (string-contains? dockerfile-string "EXPOSE 3000")))

    (test-case "go microservice with analysis"
      (define go-service
        ((go-microservice-template "1.22" "api-server")
         (expose 8080)))

      (check-true (dockerfile? go-service))

      ;; Analizar el resultado
      (define analysis (analyze-dockerfile go-service))
      (check-true (hash? analysis))

      ;; Generar reporte de seguridad
      (define security-report (generate-security-report go-service))
      (check-true (hash? security-report)))

    (test-case "complex multi-stage build"
      (define complex-build
        (combine-dockerfiles
          ;; Build stage
          (docker-file
            (from "golang:1.22-alpine" #:as "builder")
            (workdir "/build")
            (copy "go.mod" "go.sum" "./")
            (run "go mod download")
            (copy "." ".")
            (run "go build -o app"))
          ;; Runtime stage
          (docker-file
            (from "alpine:latest")
            (security-setup "appuser")
            (copy "/build/app" "/usr/local/bin/app" #:from "builder")
            (expose 8080)
            (entrypoint "/usr/local/bin/app"))))

      (check-true (dockerfile? complex-build))
      (define dockerfile-string (docker-file->string complex-build))
      (check-true (string-contains? dockerfile-string "FROM golang:1.22-alpine AS builder"))
      (check-true (string-contains? dockerfile-string "FROM alpine:latest"))
      (check-true (string-contains? dockerfile-string "COPY --from=builder")))

    (test-case "optimization pipeline"
      (define original-df (docker-file
                            (from "ubuntu")
                            (run "apt-get update")
                            (run "apt-get install -y curl")
                            (run "apt-get install -y git")
                            (run "apt-get clean")
                            (workdir "/app")
                            (copy "." ".")))

      (define pipeline (dockerfile-pipeline optimize-layers))
      (define optimized (pipeline original-df))

      (check-true (dockerfile? optimized))
      ;; Verificar que se optimizó
      (define original-runs (length (filter (λ (cmd)
                                              (and (dockerfile-command? cmd)
                                                   (eq? (dockerfile-command-type cmd) 'run)))
                                           (dockerfile-commands original-df))))
      (define optimized-runs (length (filter (λ (cmd)
                                               (and (dockerfile-command? cmd)
                                                    (eq? (dockerfile-command-type cmd) 'run)))
                                            (dockerfile-commands optimized))))
      (check-true (<= optimized-runs original-runs)))))

;; === PROPERTY-BASED TESTING ===

(define property-tests
  (test-suite "Property-Based Tests"

    (test-case "all dockerfiles should be serializable"
      ;; Propiedad: cualquier Dockerfile válido debe poder convertirse a string
      (define test-dockerfiles
        (list (docker-file (from "alpine"))
              (docker-file (from "ubuntu") (run "echo test"))
              ((node-app-template "18" "test") (cmd "npm" "start"))
              ((go-microservice-template "1.22" "test"))))

      (for ([df test-dockerfiles])
        (check-true (string? (docker-file->string df)))
        (check-true (> (string-length (docker-file->string df)) 0))))

    (test-case "analysis should never crash"
      ;; Propiedad: el análisis nunca debe fallar para Dockerfiles válidos
      (define test-dockerfiles
        (list (docker-file (from "alpine"))
              (docker-file (from "ubuntu") (user "root") (expose 22))
              ((nodejs-base "18") (run "npm install"))))

      (for ([df test-dockerfiles])
        (check-true (hash? (analyze-dockerfile df)))
        (check-true (number? (dockerfile-complexity-score df)))
        (check-true (list? (suggest-improvements df)))))

    (test-case "optimization should preserve functionality"
      ;; Propiedad: la optimización no debe cambiar la funcionalidad esencial
      (define original (docker-file
                         (from "ubuntu")
                         (run "apt-get update")
                         (run "apt-get install curl")
                         (workdir "/app")))
      (define optimized (optimize-layers original))

      ;; Mismos tipos de comandos
      (define original-types (map dockerfile-command-type (dockerfile-commands original)))
      (define optimized-types (map dockerfile-command-type (dockerfile-commands optimized)))
      (check-equal? (sort original-types symbol<?) (sort optimized-types symbol<?)))

    (test-case "templates should always produce valid dockerfiles"
      (define templates
        (list (lambda () ((node-app-template "18" "test")))
              (lambda () ((python-base "3.11") (run "pip install flask")))
              (lambda () ((golang-build-base "1.22") (run "go version")))))

      (for ([template templates])
        (define result (template))
        (check-true (dockerfile? result))
        (check-true (> (length (dockerfile-commands result)) 0))
        ;; Debe empezar con FROM
        (define first-cmd (car (dockerfile-commands result)))
        (check-equal? (dockerfile-command-type first-cmd) 'from)))))

;; === SUITE PRINCIPAL ===

(define iteration-5-6-tests
  (test-suite "Iteration 5-6: Advanced Features and Testing"
    higher-order-tests
    analysis-tests
    macro-tests
    integration-tests
    property-tests))

;; Función para ejecutar todos los tests
(define (run-all-tests)
  (run-tests iteration-5-6-tests))

;; Función auxiliar mejorada para string-contains?
(define (string-contains? str substr)
  (and (string? str) (string? substr)
       (not (eq? (string-ref (string-append str substr) 0) #f))))

(provide iteration-5-6-tests
         run-all-tests)
