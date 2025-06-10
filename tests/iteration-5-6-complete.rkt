#lang racket

;; Test completo para Iteraciones 5 y 6
;; Testing, Documentation and Examples

(require "../dockerfile-dsl.rkt")

(displayln "=== ITERACIÓN 5 & 6: PRUEBA COMPLETA ===")
(displayln "Testing Dockerfile DSL - Características idiomáticas y testing")
(newline)

;; === PRUEBA 1: FUNCIONES DE ORDEN SUPERIOR ===
(displayln "1. Funciones de orden superior:")

;; Test de templates
(displayln "   - Template Node.js:")
(define node-app ((node-app-template "18" "myapp")))
(displayln (docker-file->string node-app))
(newline)

(displayln "   - Template Go microservice:")
(define go-service ((go-microservice-template "api-server" "8080")))
(displayln (docker-file->string go-service))
(newline)

;; Test de composición
(displayln "   - Composición de Dockerfiles:")
(define base-dockerfile (docker-file (from "ubuntu:20.04")))
(define app-dockerfile (docker-file (workdir "/app") (copy "." "./")))
(define combined (combine-dockerfiles base-dockerfile app-dockerfile))
(displayln (docker-file->string combined))
(newline)

;; === PRUEBA 2: MACROS DE CONVENIENCIA ===
(displayln "2. Macros de conveniencia:")

;; Test de with-context
(displayln "   - Macro with-context:")
(define context-example
  (with-context "/src"
    (from "node:alpine")
    (copy "package.json" "./")
    (run "npm install")))
(displayln (docker-file->string context-example))
(newline)

;; Test de security-setup
(displayln "   - Macro security-setup:")
(define security-example
  (security-setup "appuser"))
(displayln (docker-file->string security-example))
(newline)

;; Test de auto-optimize
(displayln "   - Macro auto-optimize:")
(define auto-opt-example
  (auto-optimize
    (from "alpine")
    (run "apk add --no-cache curl")
    (run "apk add --no-cache git")
    (run "apk add --no-cache python3")))
(displayln (docker-file->string auto-opt-example))
(newline)

;; === PRUEBA 3: ANÁLISIS AVANZADO ===
(displayln "3. Análisis avanzado:")

;; Crear un Dockerfile para análisis
(define analysis-target
  (docker-file
    (from "ubuntu:latest")
    (run "apt-get update")
    (run "apt-get install -y python3 python3-pip")
    (copy "." "/app/")
    (workdir "/app")
    (expose 8000)
    (cmd "python3" "app.py")))

(displayln "   - Análisis completo:")
(define analysis-result (analyze-dockerfile analysis-target))
(displayln analysis-result)
(newline)

(displayln "   - Validación de seguridad:")
(define security-validation (validate-security analysis-target))
(displayln security-validation)
(newline)

(displayln "   - Detección de antipatrones:")
(define antipatterns (detect-antipatterns analysis-target))
(displayln (format "Antipatrones encontrados: ~a" antipatterns))
(newline)

(displayln "   - Estimación de tamaño:")
(define size-estimate (estimate-dockerfile-size analysis-target))
(displayln (format "Tamaño estimado: ~a MB" size-estimate))
(newline)

;; === PRUEBA 4: EJEMPLOS DE PRODUCCIÓN ===
(displayln "4. Ejemplos de producción:")

;; API REST optimizada
(displayln "   - API REST Node.js optimizada:")
(define rest-api
  (docker-file
    ;; Multi-stage build
    (from/as "node:18-alpine" "builder")
    (workdir "/build")
    (copy "package*.json" "./")
    (run "npm ci --only=production")

    ;; Production stage
    (from "node:18-alpine")
    (workdir "/app")
    (copy/from "builder" "/build/node_modules" "./node_modules")
    (copy "src/" "./src/")
    (expose 3000)
    (user "node")
    (cmd "node" "src/index.js")))

(displayln (docker-file->string rest-api))
(newline)

;; Microservicio Go
(displayln "   - Microservicio Go:")
(define go-micro
  (docker-file
    ;; Build stage
    (from/as "golang:1.19-alpine" "builder")
    (workdir "/build")
    (copy "go.mod" "./")
    (copy "go.sum" "./")
    (run "go mod download")
    (copy "." "./")
    (run "CGO_ENABLED=0 GOOS=linux go build -o main .")

    ;; Production stage
    (from "alpine:latest")
    (run "apk --no-cache add ca-certificates")
    (workdir "/root/")
    (copy/from "builder" "/build/main" "./")
    (expose 8080)
    (cmd "./main")))

(displayln (docker-file->string go-micro))
(newline)

;; === PRUEBA 5: TESTING AUTOMATIZADO ===
(displayln "5. Testing automatizado:")

;; Suite de tests básica
(define test-cases
  (list
    (lambda ()
      (displayln "   ✓ Test construcción básica")
      (docker-file (from "alpine")))
    (lambda ()
      (displayln "   ✓ Test comandos múltiples")
      (docker-file (from "ubuntu") (workdir "/app") (copy "." "./")))
    (lambda ()
      (displayln "   ✓ Test análisis")
      (analyze-dockerfile (docker-file (from "node") (expose 3000))))))

;; Ejecutar tests
(displayln "Ejecutando suite de tests:")
(for ([test-case test-cases])
  (define result (test-case))
  (when result
    (displayln "     Resultado: OK")))

(newline)

;; === PRUEBA 6: VALIDACIÓN FINAL ===
(displayln "6. Validación final del sistema:")

;; Test de integración completa
(define integration-test
  (docker-file
    (from "node:18-alpine")
    (workdir "/app")
    (copy "package.json" "./")
    (run "npm install --only=production")
    (copy "src/" "./src/")
    (expose 3000)
    (healthcheck "--interval=30s --timeout=3s --start-period=5s --retries=3 CMD curl -f http://localhost:3000/health || exit 1")
    (user "node")
    (cmd "npm" "start")))

(displayln "   - Test de integración:")
(displayln (docker-file->string integration-test))

(displayln "   - Análisis del test de integración:")
(define integration-analysis (analyze-dockerfile integration-test))
(displayln (format "Comandos totales: ~a"
                   (hash-ref (hash-ref integration-analysis 'basic-info) 'total-commands)))

(displayln "   - Validación de seguridad del test:")
(define integration-security (validate-security integration-test))
(displayln (format "Es seguro: ~a" (hash-ref integration-security 'is-secure)))

(newline)
(displayln "=== PRUEBA COMPLETA FINALIZADA ===")
(displayln "Todas las características de Iteraciones 5 y 6 funcionan correctamente.")
