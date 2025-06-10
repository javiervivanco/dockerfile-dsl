#lang racket/base

(require "../dockerfile-dsl.rkt")

;; === EJEMPLO: APLICACIÓN NODE.JS DE PRODUCCIÓN ===

(define nodejs-production-dockerfile
  ;; Usar template de Node.js como base
  ((node-app-template "18" "my-service")

   ;; === STAGE DE BUILD ===

   ;; Optimización: instalar dependencias primero para mejor caching
   (copy "package*.json" "./")
   (run "npm ci --only=production")

   ;; Copiar código fuente después de dependencias
   (copy "src/" "/app/src/")
   (copy "public/" "/app/public/")

   ;; Build de la aplicación
   (run "npm run build")

   ;; === CONFIGURACIÓN DE PRODUCCIÓN ===

   ;; Security: usuario no-root
   (security-setup "node")

   ;; Variables de entorno de producción
   (env '("NODE_ENV" . "production")
        '("PORT" . "3000")
        '("LOG_LEVEL" . "info"))

   ;; Exponer puerto de la aplicación
   (expose 3000)

   ;; Health check
   (run "npm install -g @nodejs/healthcheck")

   ;; Comando de inicio
   (cmd "npm" "start")))

;; Función para generar y mostrar el Dockerfile
(define (show-nodejs-example)
  (printf "=== NODE.JS PRODUCTION DOCKERFILE ===\n")
  (displayln (docker-file->string nodejs-production-dockerfile))
  (printf "\n=== ANÁLISIS ===\n")
  (define analysis (analyze-dockerfile nodejs-production-dockerfile))
  (printf "Complejidad: ~a/100\n" (dockerfile-complexity-score nodejs-production-dockerfile))
  (printf "Capas estimadas: ~a\n"
          (hash-ref (hash-ref analysis 'basic-info) 'total-commands))

  ;; Reporte de seguridad
  (define security-report (generate-security-report nodejs-production-dockerfile))
  (printf "Problemas de seguridad: ~a\n"
          (hash-ref (hash-ref security-report 'summary) 'total-issues)))

;; === EJEMPLO: MICROSERVICIO GO CON MULTI-STAGE ===

(define go-microservice-dockerfile
  ;; Usar template de Go microservice
  ((go-microservice-template "1.22" "auth-service")

   ;; Configuración adicional en stage final
   (env '("GIN_MODE" . "release")
        '("LOG_LEVEL" . "info")
        '("DB_POOL_SIZE" . "10"))

   ;; Exponer puerto de la API
   (expose 8080)

   ;; Health check port
   (expose 8081)))

(define (show-go-example)
  (printf "=== GO MICROSERVICE DOCKERFILE ===\n")
  (displayln (docker-file->string go-microservice-dockerfile))

  ;; Análisis específico para Go
  (printf "\n=== ANÁLISIS GO SERVICE ===\n")
  (define analysis (analyze-dockerfile go-microservice-dockerfile))
  (printf "Multi-stage build: ~a\n"
          (hash-ref (hash-ref analysis 'basic-info) 'base-images))
  (printf "Puertos expuestos: ~a\n"
          (hash-ref (hash-ref analysis 'basic-info) 'exposed-ports)))

;; === EJEMPLO: APLICACIÓN FULL-STACK ===

(define frontend-dockerfile
  (docker-file
    ;; Build stage para React
    (from "node:18-alpine" #:as "frontend-builder")
    (workdir "/app")

    ;; Dependencies
    (copy "frontend/package*.json" "./")
    (run "npm ci")

    ;; Build
    (copy "frontend/" ".")
    (run "npm run build")

    ;; Nginx serve stage
    (from "nginx:alpine")
    (copy "/app/build" "/usr/share/nginx/html" #:from "frontend-builder")
    (copy "nginx.conf" "/etc/nginx/nginx.conf")
    (expose 80)
    (cmd "nginx" "-g" "daemon off;")))

(define backend-dockerfile
  (docker-file
    ;; Build stage
    (from "python:3.11-slim" #:as "backend-builder")
    (workdir "/app")

    ;; System dependencies
    (run "apt-get update"
         "apt-get install -y --no-install-recommends build-essential"
         "rm -rf /var/lib/apt/lists/*")

    ;; Python dependencies
    (copy "backend/requirements.txt" "./")
    (run "pip install --no-cache-dir -r requirements.txt")

    ;; Runtime stage
    (from "python:3.11-slim")
    (workdir "/app")

    ;; Copy dependencies
    (copy "/usr/local/lib/python3.11/site-packages"
          "/usr/local/lib/python3.11/site-packages"
          #:from "backend-builder")
    (copy "/usr/local/bin" "/usr/local/bin" #:from "backend-builder")

    ;; Copy application
    (copy "backend/" ".")

    ;; Security
    (security-setup "appuser")

    ;; Configuration
    (env '("PYTHONPATH" . "/app")
         '("PYTHONUNBUFFERED" . "1")
         '("DJANGO_SETTINGS_MODULE" . "myapp.settings.production"))
    (expose 8000)

    ;; Health check
    (run "pip install httpx")

    ;; Start command
    (cmd "python" "-m" "uvicorn" "main:app" "--host" "0.0.0.0" "--port" "8000")))

;; Combinación usando funciones de orden superior
(define fullstack-app-dockerfiles
  (list frontend-dockerfile backend-dockerfile))

(define (show-fullstack-example)
  (printf "=== FULL-STACK APPLICATION ===\n")
  (printf "\n--- FRONTEND DOCKERFILE ---\n")
  (displayln (docker-file->string frontend-dockerfile))
  (printf "\n--- BACKEND DOCKERFILE ---\n")
  (displayln (docker-file->string backend-dockerfile))

  ;; Análisis combinado
  (printf "\n=== ANÁLISIS FULL-STACK ===\n")
  (for ([df fullstack-app-dockerfiles]
        [name '("Frontend" "Backend")])
    (printf "~a - Complejidad: ~a\n"
            name
            (dockerfile-complexity-score df))))

;; === EJEMPLO: OPTIMIZACIÓN AVANZADA ===

(define unoptimized-dockerfile
  (docker-file
    (from "ubuntu:20.04")
    (run "apt-get update")
    (run "apt-get install -y curl")
    (run "apt-get install -y git")
    (run "apt-get install -y vim")
    (run "apt-get install -y htop")
    (run "apt-get clean")
    (workdir "/app")
    (copy "app.py" ".")
    (copy "requirements.txt" ".")
    (run "pip install -r requirements.txt")
    (expose 5000)
    (cmd "python" "app.py")))

(define optimized-dockerfile
  (auto-optimize
    (from "ubuntu:20.04")
    (run "apt-get update")
    (run "apt-get install -y curl")
    (run "apt-get install -y git")
    (run "apt-get install -y vim")
    (run "apt-get install -y htop")
    (run "apt-get clean")
    (workdir "/app")
    (copy "requirements.txt" ".")
    (run "pip install -r requirements.txt")
    (copy "app.py" ".")
    (expose 5000)
    (cmd "python" "app.py")))

(define (show-optimization-example)
  (printf "=== EJEMPLO DE OPTIMIZACIÓN ===\n")
  (printf "\n--- ORIGINAL (NO OPTIMIZADO) ---\n")
  (displayln (docker-file->string unoptimized-dockerfile))
  (printf "Capas RUN: ~a\n"
          (length (filter (λ (cmd) (eq? (dockerfile-command-type cmd) 'run))
                         (dockerfile-commands unoptimized-dockerfile))))

  (printf "\n--- OPTIMIZADO ---\n")
  (displayln (docker-file->string optimized-dockerfile))
  (printf "Capas RUN: ~a\n"
          (length (filter (λ (cmd) (eq? (dockerfile-command-type cmd) 'run))
                         (dockerfile-commands optimized-dockerfile)))))

;; === EJEMPLO: ANÁLISIS DE SEGURIDAD ===

(define insecure-dockerfile
  (docker-file
    (from "ubuntu:20.04")
    (run "apt-get update" "apt-get install -y openssh-server")
    (env '("ROOT_PASSWORD" . "admin123")
         '("API_KEY" . "secret-key-123"))
    (expose 22 80 3306)
    (copy "app/" "/app/")
    (workdir "/app")
    (cmd "python" "app.py")))

(define secure-dockerfile
  (docker-file
    (from "ubuntu:20.04")
    (run "apt-get update"
         "apt-get install -y --no-install-recommends python3 python3-pip"
         "rm -rf /var/lib/apt/lists/*")
    (security-setup "appuser")
    (workdir "/app")
    (copy "requirements.txt" ".")
    (run "pip3 install --no-cache-dir -r requirements.txt")
    (copy "app/" ".")
    (env '("FLASK_ENV" . "production"))
    (expose 8080)
    (cmd "python3" "app.py")))

(define (show-security-example)
  (printf "=== COMPARACIÓN DE SEGURIDAD ===\n")
  (printf "\n--- DOCKERFILE INSEGURO ---\n")
  (displayln (docker-file->string insecure-dockerfile))
  (define insecure-report (generate-security-report insecure-dockerfile))
  (printf "Problemas de seguridad: ~a\n"
          (hash-ref (hash-ref insecure-report 'summary) 'total-issues))

  (printf "\n--- DOCKERFILE SEGURO ---\n")
  (displayln (docker-file->string secure-dockerfile))
  (define secure-report (generate-security-report secure-dockerfile))
  (printf "Problemas de seguridad: ~a\n"
          (hash-ref (hash-ref secure-report 'summary) 'total-issues)))

;; === FUNCIONES PRINCIPALES DE DEMOSTRACIÓN ===

(define (run-all-examples)
  (printf "========================================\n")
  (printf "EJEMPLOS DE PRODUCCIÓN - ITERACIÓN 5-6\n")
  (printf "========================================\n\n")

  (show-nodejs-example)
  (printf "\n" (make-string 50 #\-) "\n\n")

  (show-go-example)
  (printf "\n" (make-string 50 #\-) "\n\n")

  (show-fullstack-example)
  (printf "\n" (make-string 50 #\-) "\n\n")

  (show-optimization-example)
  (printf "\n" (make-string 50 #\-) "\n\n")

  (show-security-example)
  (printf "\n========================================\n")
  (printf "FIN DE EJEMPLOS\n")
  (printf "========================================\n"))

;; Exports
(provide nodejs-production-dockerfile
         go-microservice-dockerfile
         frontend-dockerfile
         backend-dockerfile
         fullstack-app-dockerfiles
         optimized-dockerfile
         secure-dockerfile
         run-all-examples
         show-nodejs-example
         show-go-example
         show-fullstack-example
         show-optimization-example
         show-security-example)
