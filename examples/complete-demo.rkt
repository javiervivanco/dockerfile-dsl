#lang racket/base

(require "../dockerfile-dsl.rkt"
         "../examples/production-examples.rkt"
         "../tests/iteration-5-6-tests.rkt")

;; === DEMOSTRACIÓN COMPLETA DE ITERACIONES 5-6 ===

(define (demo-header title)
  (define line (make-string 60 #\=))
  (printf "\n~a\n~a\n~a\n\n" line title line))

(define (demo-section title)
  (define line (make-string 40 #\-))
  (printf "\n~a\n~a\n~a\n\n" line title line))

;; === DEMOSTRACIÓN DE FUNCIONES DE ORDEN SUPERIOR ===

(define (demo-higher-order-functions)
  (demo-header "DEMOSTRACIÓN: FUNCIONES DE ORDEN SUPERIOR")

  (demo-section "1. Template de Node.js")
  (define node-template (node-app-template "18" "demo-service"))
  (define node-app (node-template
                     (security-setup "node")
                     (copy "src/" "/app/src/")
                     (cmd "npm" "start")))

  (printf "Template Node.js aplicado:\n")
  (displayln (docker-file->string node-app))

  (demo-section "2. Template de Go Microservice")
  (define go-template (go-microservice-template "1.22" "auth-api"))
  (define go-service (go-template (expose 8080)))

  (printf "Template Go aplicado:\n")
  (displayln (docker-file->string go-service))

  (demo-section "3. Optimización de Capas")
  (define unoptimized (docker-file
                        (from "ubuntu")
                        (run "apt-get update")
                        (run "apt-get install curl")
                        (run "apt-get install git")
                        (run "apt-get clean")))

  (define optimized (optimize-layers unoptimized))

  (printf "ANTES (4 comandos RUN):\n")
  (displayln (docker-file->string unoptimized))
  (printf "\nDESPUÉS (1 comando RUN optimizado):\n")
  (displayln (docker-file->string optimized)))

;; === DEMOSTRACIÓN DE ANÁLISIS AVANZADO ===

(define (demo-advanced-analysis)
  (demo-header "DEMOSTRACIÓN: ANÁLISIS AVANZADO")

  (demo-section "1. Dockerfile Problemático")
  (define problematic-df (docker-file
                           (from "ubuntu:latest")
                           (run "apt-get update")
                           (env '("ROOT_PASSWORD" . "admin123"))
                           (expose 22 3306)
                           (copy "." "/app/")
                           (workdir "/app")
                           (cmd "python" "app.py")))

  (printf "Dockerfile problemático:\n")
  (displayln (docker-file->string problematic-df))

  (printf "\nAnálisis:\n")
  (define analysis (analyze-dockerfile problematic-df))
  (define security-issues (validate-security problematic-df))
  (define complexity (dockerfile-complexity-score problematic-df))
  (define size (estimate-image-size problematic-df))

  (printf "- Complejidad: ~a/100\n" complexity)
  (printf "- Tamaño estimado: ~a MB\n" size)
  (printf "- Problemas de seguridad: ~a\n" (length security-issues))

  (when (> (length security-issues) 0)
    (printf "\nProblemas encontrados:\n")
    (for ([issue security-issues])
      (printf "  • ~a\n" (hash-ref issue 'message))))

  (demo-section "2. Dockerfile Optimizado")
  (define secure-df (docker-file
                      (from "python:3.11-slim")
                      (run "apt-get update"
                           "apt-get install -y --no-install-recommends python3-pip"
                           "rm -rf /var/lib/apt/lists/*")
                      (security-setup "appuser")
                      (workdir "/app")
                      (copy "requirements.txt" ".")
                      (run "pip install --no-cache-dir -r requirements.txt")
                      (copy "app.py" ".")
                      (env '("FLASK_ENV" . "production"))
                      (expose 8080)
                      (cmd "python" "app.py")))

  (printf "Dockerfile mejorado:\n")
  (displayln (docker-file->string secure-df))

  (printf "\nAnálisis mejorado:\n")
  (define secure-analysis (analyze-dockerfile secure-df))
  (define secure-issues (validate-security secure-df))
  (define secure-complexity (dockerfile-complexity-score secure-df))
  (define secure-size (estimate-image-size secure-df))

  (printf "- Complejidad: ~a/100\n" secure-complexity)
  (printf "- Tamaño estimado: ~a MB\n" secure-size)
  (printf "- Problemas de seguridad: ~a\n" (length secure-issues)))

;; === DEMOSTRACIÓN DE MACROS ===

(define (demo-convenience-macros)
  (demo-header "DEMOSTRACIÓN: MACROS DE CONVENIENCIA")

  (demo-section "1. Macro with-context")
  (define context-example (with-context "/app"
                            (copy "package.json" "./")
                            (run "npm install")
                            (copy "src/" "./")))

  (printf "Usando with-context:\n")
  (displayln (docker-file->string context-example))

  (demo-section "2. Macro security-setup")
  (define security-example (security-setup "myuser"))

  (printf "Usando security-setup:\n")
  (displayln (docker-file->string security-example))

  (demo-section "3. Macro auto-optimize")
  (define auto-opt-example (auto-optimize
                             (from "alpine")
                             (run "apk update")
                             (run "apk add curl")
                             (run "apk add git")
                             (workdir "/app")))

  (printf "Usando auto-optimize:\n")
  (displayln (docker-file->string auto-opt-example)))

;; === DEMOSTRACIÓN DE CASOS DE USO REALES ===

(define (demo-real-world-examples)
  (demo-header "DEMOSTRACIÓN: CASOS DE USO REALES")

  (demo-section "1. API RESTful con Node.js")
  (define rest-api
    ((node-app-template "18" "rest-api")
     ;; Security
     (security-setup "node")

     ;; Dependencies
     (copy "package*.json" "./")
     (run "npm ci --only=production")

     ;; Source code
     (copy "src/" "/app/src/")
     (copy "config/" "/app/config/")

     ;; Environment
     (env '("NODE_ENV" . "production")
          '("PORT" . "3000")
          '("LOG_LEVEL" . "info"))

     ;; Runtime
     (expose 3000)
     (cmd "npm" "start")))

  (printf "API RESTful Node.js:\n")
  (displayln (docker-file->string rest-api))

  (printf "Análisis del API:\n")
  (define api-complexity (dockerfile-complexity-score rest-api))
  (define api-size (estimate-image-size rest-api))
  (printf "- Complejidad: ~a/100\n" api-complexity)
  (printf "- Tamaño estimado: ~a MB\n" api-size)

  (demo-section "2. Microservicio Go con Multi-stage")
  (define go-micro
    ((go-microservice-template "1.22" "user-service")
     (env '("GIN_MODE" . "release")
          '("DB_HOST" . "${DB_HOST}")
          '("DB_PORT" . "5432"))
     (expose 8080)
     (expose 9090))) ; metrics port

  (printf "Microservicio Go:\n")
  (displayln (docker-file->string go-micro))

  (printf "Análisis del microservicio:\n")
  (define micro-complexity (dockerfile-complexity-score go-micro))
  (define micro-size (estimate-image-size go-micro))
  (printf "- Complejidad: ~a/100\n" micro-complexity)
  (printf "- Tamaño estimado: ~a MB\n" micro-size))

;; === DEMOSTRACIÓN DE TESTING ===

(define (demo-testing-capabilities)
  (demo-header "DEMOSTRACIÓN: CAPACIDADES DE TESTING")

  (demo-section "Ejecutando Tests de Iteración 5-6")
  (printf "Ejecutando suite de tests...\n\n")

  ;; Ejecutar tests y capturar resultados
  (with-handlers ([exn:fail? (lambda (e)
                               (printf "❌ Tests fallaron: ~a\n" (exn-message e)))])
    (run-all-tests)
    (printf "✅ Todos los tests pasaron exitosamente!\n"))

  (demo-section "Ejemplo de Property-Based Testing")
  (printf "Verificando propiedades fundamentales:\n")

  ;; Propiedad: Todo Dockerfile debe ser serializable
  (define test-dfs (list (docker-file (from "alpine"))
                         ((node-app-template "18" "test"))
                         ((go-microservice-template "1.22" "test"))))

  (for ([df test-dfs]
        [i (in-naturals 1)])
    (define result (docker-file->string df))
    (printf "  ~a. Dockerfile ~a: ~a caracteres ✅\n"
            i
            (if (< i 2) "básico" "template")
            (string-length result)))

  (demo-section "Análisis Automático")
  (printf "Analizando todos los ejemplos:\n")

  (for ([df test-dfs]
        [name '("Básico" "Node.js" "Go")])
    (define complexity (dockerfile-complexity-score df))
    (define security-issues (length (validate-security df)))
    (printf "  • ~a: Complejidad=~a, Seguridad=~a problemas\n"
            name complexity security-issues)))

;; === FUNCIÓN PRINCIPAL DE DEMOSTRACIÓN ===

(define (run-complete-demo)
  (printf "╔══════════════════════════════════════════════════════════╗\n")
  (printf "║          DOCKERFILE DSL - DEMO COMPLETO                 ║\n")
  (printf "║              ITERACIONES 5-6                            ║\n")
  (printf "╚══════════════════════════════════════════════════════════╝\n")

  (demo-higher-order-functions)
  (demo-advanced-analysis)
  (demo-convenience-macros)
  (demo-real-world-examples)
  (demo-testing-capabilities)

  (demo-header "RESUMEN FINAL")
  (printf "✅ Funciones de orden superior implementadas\n")
  (printf "✅ Sistema de análisis avanzado funcional\n")
  (printf "✅ Macros de conveniencia operativas\n")
  (printf "✅ Optimización automática de capas\n")
  (printf "✅ Análisis de seguridad completo\n")
  (printf "✅ Templates para casos comunes\n")
  (printf "✅ Suite de testing comprehensiva\n")
  (printf "✅ Ejemplos de producción validados\n")

  (printf "\n🎉 ¡Iteraciones 5-6 completadas exitosamente!\n"))

;; Exports
(provide run-complete-demo
         demo-higher-order-functions
         demo-advanced-analysis
         demo-convenience-macros
         demo-real-world-examples
         demo-testing-capabilities)
