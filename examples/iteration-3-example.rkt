#lang racket/base

(require "../dockerfile-dsl.rkt")

;; Ejemplo de multi-stage build con opciones avanzadas (Go application)
(define go-multistage-dockerfile
  (docker-file
    ;; Build arguments
    (arg "GO_VERSION" "1.22")
    (arg "ALPINE_VERSION" "3.18")

    ;; Build stage
    (from/as "golang:1.22-alpine" "builder")
    (label '("stage" . "builder") '("purpose" . "compilation"))
    (workdir "/build")

    ;; Install build dependencies
    (run "apk add --no-cache git ca-certificates")

    ;; Copy go mod files for better layer caching
    (copy "go.mod" "./")
    (copy "go.sum" "./")

    ;; Download dependencies with cache mount
    (run/mount '((type . "cache") (target . "/go/pkg/mod"))
               "go mod download")

    ;; Copy source code
    (copy "." ".")

    ;; Build the application with cache mount
    (run/mount '((type . "cache") (target . "/go/pkg/mod"))
               "CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app ./cmd/main")

    ;; Final stage
    (from "alpine:3.18")
    (label '("version" . "1.0.0")
           '("maintainer" . "dev@company.com")
           '("description" . "Go microservice"))

    ;; Install runtime dependencies
    (run "apk --no-cache add ca-certificates")
    (workdir "/root/")

    ;; Copy binary from builder stage
    (copy/from "builder" "/build/app" "./")

    ;; Expose port and set command
    (expose 8080)
    (cmd "./app")))

;; Ejemplo de desarrollo con bind mounts
(define dev-dockerfile
  (docker-file
    (from "node:18-alpine")
    (workdir "/app")

    ;; Variables de entorno para desarrollo
    (env '("NODE_ENV" . "development")
         '("DEBUG" . "*"))

    ;; Instalar dependencias globales
    (run "npm install -g nodemon")

    ;; Copy package files
    (copy "package*.json" "./")

    ;; Install dependencies with npm cache mount
    (run/mount '((type . "cache") (target . "/root/.npm"))
               "npm ci")

    ;; En desarrollo, el código se monta como volumen
    ;; Este Dockerfile se usa como base
    (expose 3000 9229)
    (cmd "nodemon" "--inspect=0.0.0.0:9229" "index.js")))

;; Ejemplo complejo con múltiples stages y opciones
(define complex-webapp-dockerfile
  (docker-file
    ;; Arguments para configuración
    (arg "NODE_VERSION" "18")
    (arg "NGINX_VERSION" "1.24")

    ;; Frontend build stage
    (from/as "node:18-alpine" "frontend-builder")
    (workdir "/app")
    (copy "frontend/package*.json" "./")
    (run/mount '((type . "cache") (target . "/root/.npm"))
               "npm ci --only=production")
    (copy "frontend/" ".")
    (run "npm run build")

    ;; Backend build stage
    (from/as "node:18-alpine" "backend-builder")
    (workdir "/app")
    (copy "backend/package*.json" "./")
    (run/mount '((type . "cache") (target . "/root/.npm"))
               "npm ci --only=production")
    (copy "backend/" ".")

    ;; Production stage
    (from "nginx:1.24-alpine")
    (label '("app" . "webapp")
           '("version" . "2.0.0")
           '("tier" . "production"))

    ;; Copy nginx config
    (copy "nginx.conf" "/etc/nginx/nginx.conf")

    ;; Copy built frontend
    (copy/from "frontend-builder" "/app/dist" "/usr/share/nginx/html")

    ;; Copy backend (to be served by separate container typically)
    (copy/from "backend-builder" "/app" "/opt/backend")

    (expose 80 443)
    (cmd "nginx" "-g" "daemon off;")))

;; Mostrar resultados
(displayln "=== Multi-stage Go Application ===")
(displayln (docker-file->string go-multistage-dockerfile))
(displayln "")
(displayln "=== Development Environment ===")
(displayln (docker-file->string dev-dockerfile))
(displayln "")
(displayln "=== Complex Web Application ===")
(displayln (docker-file->string complex-webapp-dockerfile))

;; Validaciones
(displayln "")
(displayln "=== Validaciones ===")
(displayln (format "Go app válida: ~a" (validate-dockerfile-structure go-multistage-dockerfile)))
(displayln (format "Dev env válida: ~a" (validate-dockerfile-structure dev-dockerfile)))
(displayln (format "Complex webapp válida: ~a" (validate-dockerfile-structure complex-webapp-dockerfile)))
