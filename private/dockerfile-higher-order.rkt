#lang racket/base

(require "dockerfile-core.rkt"
         "dockerfile-ir.rkt"
         "dockerfile-commands.rkt"
         "dockerfile-formatter.rkt"
         racket/list
         racket/string)

(provide base-image
         with-workdir
         with-user
         with-env
         nodejs-base
         python-base
         golang-build-base
         compose-stages
         apply-pattern
         ;; === NUEVAS FUNCIONES DE ITERACIÓN 5 ===
         node-app-template
         go-microservice-template
         combine-dockerfiles
         dockerfile-pipeline
         optimize-layers
         cached-analyze)

;; Función de orden superior para crear bases reutilizables
(define (base-image image)
  (lambda commands
    (apply docker-file (from image) commands)))

;; Wrapper para configurar workdir y ejecutar comandos
(define (with-workdir path)
  (lambda commands
    (cons (workdir path) commands)))

;; Wrapper para configurar usuario
(define (with-user user-spec)
  (lambda commands
    (cons (user user-spec) commands)))

;; Wrapper para configurar variables de entorno
(define (with-env . env-pairs)
  (lambda commands
    (cons (apply env env-pairs) commands)))

;; Base preconfigurada para Node.js
(define (nodejs-base version)
  (lambda commands
    (apply docker-file
           (from (format "node:~a-alpine" version))
           (run "npm install -g npm@latest")
           ((with-workdir "/app") commands))))

;; Base preconfigurada para Python
(define (python-base version)
  (lambda commands
    (apply docker-file
           (from (format "python:~a-slim" version))
           (run "pip install --upgrade pip")
           ((with-workdir "/app") commands))))

;; Base preconfigurada para Go builds
(define (golang-build-base version)
  (lambda commands
    (apply docker-file
           (from (format "golang:~a-alpine" version))
           (run "apk add --no-cache git ca-certificates")
           ((with-workdir "/build") commands))))

;; Función para componer múltiples stages
(define (compose-stages . stages)
  (apply docker-file
         (apply append
                (map dockerfile-commands stages))))

;; Aplicar un patrón común a múltiples comandos
;; Aplicar un patrón común a múltiples comandos
(define (apply-pattern pattern . args)
  (apply pattern args))

;; === NUEVAS FUNCIONES DE ORDEN SUPERIOR (Iteración 5) ===

;; Template system para aplicaciones comunes
(define (node-app-template version app-name)
  (lambda commands
    (apply docker-file
      (from (format "node:~a-alpine" version))
      (workdir "/app")
      (copy "package*.json" "./")
      (run "npm ci --only=production")
      (copy "." ".")
      (env '("NODE_ENV" . "production"))
      (expose 3000)
      commands)))

;; Template para microservicios Go
(define (go-microservice-template version app-name)
  (lambda commands
    (apply docker-file
      ;; Build stage
      (from/as (format "golang:~a-alpine" version) "builder")
      (run "apk --no-cache add ca-certificates git")
      (workdir "/build")
      (env '("CGO_ENABLED" . "0") '("GOOS" . "linux") '("GOARCH" . "amd64"))
      (copy "go.mod" "./")
      (copy "go.sum" "./")
      (run "go mod download")
      (copy "." ".")
      (run (format "go build -ldflags='-w -s' -o ~a ./cmd" app-name))
      ;; Final stage
      (from "scratch")
      (copy/from "builder" "/etc/ssl/certs/ca-certificates.crt" "/etc/ssl/certs/")
      (copy/from "builder" (format "/build/~a" app-name) (format "/~a" app-name))
      (entrypoint (format "/~a" app-name))
      commands)))

;; Composición funcional de Dockerfiles
(define (combine-dockerfiles . dockerfiles)
  (apply docker-file
         (apply append
                (map dockerfile-commands dockerfiles))))

;; Pipeline de transformaciones
(define (dockerfile-pipeline . transformations)
  (lambda (df)
    (foldl (lambda (transform acc) (transform acc))
           df
           transformations)))

;; Transformación para optimizar capas
(define (optimize-layers df)
  ;; Combina comandos RUN consecutivos
  (define (combine-run-commands run-group)
    (run (string-join (reverse run-group) " && ")))
  
  (define optimized-commands
    (let loop ([commands (dockerfile-commands df)]
               [acc '()]
               [run-group '()])
      (cond
        [(null? commands)
         (if (null? run-group)
             (reverse acc)
             (reverse (cons (combine-run-commands run-group) acc)))]
        [(and (dockerfile-command? (car commands))
              (eq? (dockerfile-command-type (car commands)) 'run))
         (loop (cdr commands)
               acc
               (cons (car (dockerfile-command-args (car commands))) run-group))]
        [else
         (define new-acc
           (if (null? run-group)
               (cons (car commands) acc)
               (cons (car commands)
                     (cons (combine-run-commands run-group) acc))))
         (loop (cdr commands) new-acc '())])))
  (dockerfile optimized-commands))

;; Análisis de dockerfile
(define (analyze-dockerfile df)
  (define commands (dockerfile-commands df))
  (hash 'total-commands (length commands)
        'base-image (extract-base-image commands)
        'exposed-ports (extract-exposed-ports commands)
        'estimated-layers (estimate-layers commands)
        'has-multi-stage (has-multi-stage? commands)))

(define (extract-base-image commands)
  (define first-from (findf (lambda (cmd)
                              (and (dockerfile-command? cmd)
                                   (eq? (dockerfile-command-type cmd) 'from)))
                            commands))
  (if first-from
      (car (dockerfile-command-args first-from))
      #f))

(define (extract-exposed-ports commands)
  (filter (lambda (cmd)
                (if (and (dockerfile-command? cmd)
                         (eq? (dockerfile-command-type cmd) 'expose))
                    (dockerfile-command-args cmd)
                    #f))
              commands))

(define (estimate-layers commands)
  ;; Cada comando que crea una nueva capa
  (length (filter (lambda (cmd)
                    (and (dockerfile-command? cmd)
                         (member (dockerfile-command-type cmd)
                                '(from run copy add))))
                  commands)))

(define (has-multi-stage? commands)
  (> (length (filter (lambda (cmd)
                       (and (dockerfile-command? cmd)
                            (eq? (dockerfile-command-type cmd) 'from)))
                     commands))
     1))

;; Funciones de validación avanzada
(define (validate-security df)
  (define commands (dockerfile-commands df))
  (define issues '())

  ;; Verificar uso de root
  (unless (findf (lambda (cmd)
                   (and (dockerfile-command? cmd)
                        (eq? (dockerfile-command-type cmd) 'user)))
                 commands)
    (set! issues (cons "No USER command found - running as root" issues)))

  ;; Verificar exposición de puertos comunes problemáticos
  (define exposed (extract-exposed-ports commands))
  (when (member 22 (apply append exposed))
    (set! issues (cons "SSH port 22 exposed" issues)))

  issues)

;; Cache y memoización básica
(define analysis-cache (make-hash))

(define (cached-analyze df)
  (define df-hash (equal-hash-code df))
  (hash-ref analysis-cache df-hash
            (lambda ()
              (define analysis (analyze-dockerfile df))
              (hash-set! analysis-cache df-hash analysis)
              analysis)))
