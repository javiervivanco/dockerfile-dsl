#lang racket/base

(require "../dockerfile-dsl.rkt"
         racket/list)

;; Ejemplo de aplicación web completa con todos los comandos avanzados
(define complete-webapp-dockerfile
  (docker-file
    ;; Build arguments y metadata
    (arg "NODE_VERSION" "18")
    (from "node:18-alpine")
    (label '("version" . "2.0.0")
           '("maintainer" . "devops@company.com")
           '("description" . "Complete web application with health monitoring"))

    ;; Configuración de usuario y permisos
    (run "addgroup -g 1001 -S nodejs")
    (run "adduser -S nextjs -u 1001")
    (user "nextjs")

    ;; Configuración de aplicación
    (workdir "/app")
    (env '("NODE_ENV" . "production")
         '("PORT" . "3000"))

    ;; Instalación de dependencias
    (copy "package*.json" "./")
    (run "npm ci --only=production" "npm cache clean --force")

    ;; Código de aplicación
    (copy "." ".")

    ;; Configuración de volúmenes para datos persistentes
    (volume "/app/data" "/app/logs")

    ;; Puerto y healthcheck
    (expose 3000)
    (healthcheck "CMD wget --no-verbose --tries=1 --spider http://localhost:3000/api/health || exit 1")

    ;; Entrypoint personalizado
    (entrypoint "node" "server.js")))

;; Ejemplo de base de datos con configuración completa
(define database-dockerfile
  (docker-file
    (from "postgres:15-alpine")

    ;; Metadata completa
    (label '("service" . "database")
           '("version" . "15.0")
           '("environment" . "production"))

    ;; Variables de entorno
    (env '("POSTGRES_DB" . "appdb")
         '("POSTGRES_USER" . "appuser")
         '("POSTGRES_PASSWORD" . "securepassword"))

    ;; Scripts de inicialización
    (copy "init-scripts/" "/docker-entrypoint-initdb.d/")

    ;; Volúmenes para persistencia
    (volume "/var/lib/postgresql/data")

    ;; Puerto
    (expose 5432)

    ;; Health check para PostgreSQL
    (healthcheck "CMD pg_isready -U $POSTGRES_USER -d $POSTGRES_DB || exit 1")

    ;; Usuario específico (ya definido en imagen base)
    (user "postgres")))

;; Ejemplo de microservicio con multi-stage avanzado
(define microservice-dockerfile
  (docker-file
    ;; Stage 1: Dependencies
    (from/as "node:18-alpine" "deps")
    (workdir "/app")
    (copy "package*.json" "./")
    (run "npm ci --only=production")

    ;; Stage 2: Build
    (from/as "node:18-alpine" "builder")
    (workdir "/app")
    (copy "package*.json" "./")
    (run "npm ci")
    (copy "." ".")
    (run "npm run build")

    ;; Stage 3: Runtime
    (from "node:18-alpine")
    (label '("type" . "microservice")
           '("stage" . "production"))

    ;; Usuario no-root para seguridad
    (run "addgroup -g 1001 -S nodejs")
    (run "adduser -S microservice -u 1001")
    (user "microservice")

    (workdir "/app")

    ;; Copiar dependencias y build
    (copy/from "deps" "/app/node_modules" "./node_modules")
    (copy/from "builder" "/app/dist" "./dist")
    (copy "package.json" "./")

    ;; Configuración runtime
    (env '("NODE_ENV" . "production"))
    (expose 8080)
    (volume "/app/config")

    ;; Health monitoring
    (healthcheck "CMD curl -f http://localhost:8080/health || exit 1")

    ;; Entrypoint con manejo de señales
    (entrypoint "node" "dist/server.js")))

;; Ejemplo con validaciones y optimizaciones
(define optimized-dockerfile
  (docker-file
    (from "alpine:3.18")
    (label '("optimized" . "true"))

    ;; Instalar todo en una sola capa RUN
    (run "apk add --no-cache"
         "    nodejs"
         "    npm"
         "    curl"
         "&& npm install -g pm2"
         "&& adduser -D -s /bin/sh appuser")

    (user "appuser")
    (workdir "/app")

    ;; Copy optimizado
    (copy "package*.json" "./")
    (run "npm ci --production" "npm cache clean --force")
    (copy "." ".")

    (expose 3000)
    (volume "/app/data")
    (healthcheck "CMD curl -f http://localhost:3000/ping || exit 1")
    (entrypoint "pm2-runtime" "start" "ecosystem.config.js")))

;; Mostrar resultados
(displayln "=== Complete Web Application ===")
(displayln (docker-file->string complete-webapp-dockerfile))
(displayln "")
(displayln "=== Database Configuration ===")
(displayln (docker-file->string database-dockerfile))
(displayln "")
(displayln "=== Microservice Multi-stage ===")
(displayln (docker-file->string microservice-dockerfile))
(displayln "")
(displayln "=== Optimized Dockerfile ===")
(displayln (docker-file->string optimized-dockerfile))

;; Validaciones avanzadas
(displayln "")
(displayln "=== Validaciones Avanzadas ===")
(displayln (format "Webapp válida: ~a" (validate-dockerfile-advanced complete-webapp-dockerfile)))
(displayln (format "Database válida: ~a" (validate-dockerfile-advanced database-dockerfile)))
(displayln (format "Microservice válida: ~a" (validate-dockerfile-advanced microservice-dockerfile)))
(displayln (format "Optimized válida: ~a" (validate-dockerfile-advanced optimized-dockerfile)))

;; Validar dependencias multi-stage
(displayln "")
(displayln "=== Validación Multi-stage ===")
(displayln (format "Microservice dependencies: ~a" (validate-multistage-dependencies microservice-dockerfile)))
(define stage-refs (check-stage-references microservice-dockerfile))
(if (empty? stage-refs)
    (displayln "✅ Todas las referencias de stages son válidas")
    (displayln (format "❌ Referencias indefinidas: ~a" stage-refs)))

;; Sugerencias de optimización
(displayln "")
(displayln "=== Sugerencias de Optimización ===")
(define suggestions (suggest-optimizations complete-webapp-dockerfile))
(if (empty? suggestions)
    (displayln "✅ No hay sugerencias de optimización")
    (for-each (lambda (suggestion)
                (displayln (format "💡 ~a" suggestion)))
              suggestions))
