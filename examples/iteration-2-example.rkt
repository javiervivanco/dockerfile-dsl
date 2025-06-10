#lang racket/base

(require "../dockerfile-dsl.rkt")

;; Ejemplo más avanzado usando comandos de la Iteración 2
(define nodejs-app-dockerfile
  (docker-file
    (from "node:18-alpine")
    (workdir "/app")

    ;; Variables de entorno
    (env '("NODE_ENV" . "production")
         '("PORT" . "3000")
         '("DEBUG" . "false"))

    ;; Instalar dependencias en una capa separada para mejor caching
    (copy "package*.json" "./")
    (run "npm ci" "npm cache clean --force")

    ;; Copiar código fuente
    (copy "." ".")

    ;; Exponer puertos
    (expose 3000 9229)  ; Puerto de app y debugging

    ;; Comando de inicio usando exec form
    (cmd "node" "index.js")))

;; Ejemplo de aplicación web con múltiples servicios
(define web-app-dockerfile
  (docker-file
    (from "ubuntu:22.04")
    (workdir "/app")

    ;; Instalar múltiples paquetes en una sola capa
    (run "apt-get update"
         "apt-get install -y python3 python3-pip nginx"
         "apt-get clean"
         "rm -rf /var/lib/apt/lists/*")

    ;; Variables de configuración
    (env '("PYTHONPATH" . "/app")
         '("FLASK_ENV" . "production"))

    ;; Copiar archivos de configuración
    (copy "requirements.txt" "./")
    (copy "nginx.conf" "/etc/nginx/")

    ;; Instalar dependencias Python
    (run "pip3 install -r requirements.txt")

    ;; Copiar código de la aplicación
    (add "app.tar.gz" "/app/")

    ;; Exponer puertos para web y admin
    (expose 80 443 8080)

    ;; Script de inicio
    (cmd "/app/start.sh")))

;; Mostrar resultados
(displayln "=== Dockerfile Node.js App ===")
(displayln (docker-file->string nodejs-app-dockerfile))
(displayln "")
(displayln "=== Dockerfile Web App ===")
(displayln (docker-file->string web-app-dockerfile))
(displayln "")
(displayln "=== Validación ===")
(displayln (format "Node.js app válida: ~a" (validate-dockerfile-structure nodejs-app-dockerfile)))
(displayln (format "Web app válida: ~a" (validate-dockerfile-structure web-app-dockerfile)))
