#lang racket/base

(require (for-syntax racket/base
                     racket/syntax)
         "dockerfile-core.rkt"
         "dockerfile-commands.rkt"
         "dockerfile-higher-order.rkt")

(provide with-stage
         multi-stage
         optimize-runs
         define-dockerfile
         docker-compose
         ;; Macros adicionales para Iteración 5
         with-context
         install-packages
         security-setup
         copy-pattern
         auto-optimize)

;; Macro para definir un stage con nombre
(define-syntax (with-stage stx)
  (syntax-case stx ()
    [(_ stage-name base-image body ...)
     #'(docker-file
         (from/as base-image (symbol->string 'stage-name))
         body ...)]))

;; Macro para multi-stage builds más legibles
(define-syntax (multi-stage stx)
  (syntax-case stx ()
    [(_ [stage-name base-image stage-body ...] ... final-stage)
     #'(compose-stages
         (with-stage stage-name base-image stage-body ...) ...
         final-stage)]))

;; Macro para optimizar múltiples RUN consecutivos
(define-syntax (optimize-runs stx)
  (syntax-case stx ()
    [(_ cmd ...)
     #'(run cmd ...)]))

;; Macro para definir Dockerfiles con nombre
(define-syntax (define-dockerfile stx)
  (syntax-case stx ()
    [(_ name body ...)
     #'(define name (docker-file body ...))]))

;; === NUEVAS MACROS DE CONVENIENCIA (Iteración 5) ===

;; Macro para contexto de trabajo con directorio
(define-syntax (with-context stx)
  (syntax-case stx ()
    [(_ workdir-path body ...)
     #'(docker-file
         (workdir workdir-path)
         body ...)]))

;; Macro para instalación de paquetes según el sistema - simplificada
(define-syntax (install-packages stx)
  (syntax-case stx ()
    [(_ 'apt pkg ...)
     #'(run "apt-get update" 
            "apt-get install -y pkg ..."
            "rm -rf /var/lib/apt/lists/*")]
    [(_ 'apk pkg ...)
     #'(run "apk add --no-cache pkg ...")]
    [(_ 'npm pkg ...)
     #'(run "npm install -g pkg ...")]
    [(_ 'pip pkg ...)
     #'(run "pip install pkg ...")]))

;; Macro para configuración de seguridad común
(define-syntax (security-setup stx)
  (syntax-case stx ()
    [(_ username)
     #'(docker-file
         (run (format "adduser --disabled-password --gecos '' ~a" username))
         (user username))]))

;; Macro para desarrollo vs producción - versión simplificada
(define-syntax (env-conditional stx)
  (syntax-case stx ()
    [(_ env-var dev-command prod-command)
     #'(if (equal? (getenv env-var) "development")
           dev-command
           prod-command)]))

;; Macro para copy con patrones comunes
(define-syntax (copy-pattern stx)
  (syntax-case stx ()
    [(_ 'source-code dest)
     #'(docker-file
         (copy "src/" dest)
         (copy "*.json" dest)
         (copy "*.js" dest))]
    [(_ 'node-deps dest)
     #'(copy "package*.json" dest)]
    [(_ 'python-deps dest)
     #'(copy "requirements*.txt" dest)]
    [(_ 'go-deps dest)
     #'(copy "go.mod" "go.sum" dest)]))

;; Macro para health checks comunes
(define-syntax (standard-healthcheck stx)
  (syntax-case stx ()
    [(_ 'http port path)
     #'(run (format "curl --fail http://localhost:~a~a || exit 1" port path))]
    [(_ 'tcp port)
     #'(run (format "nc -z localhost ~a || exit 1" port))]
    [(_ 'ping)
     #'(run "ping -c 1 localhost || exit 1")]))

;; Macro para optimización automática
(define-syntax (auto-optimize stx)
  (syntax-case stx ()
    [(_ body ...)
     #'(optimize-layers
         (docker-file body ...))]))

;; Macro para builds condicionales
(define-syntax (conditional-build stx)
  (syntax-case stx ()
    [(_ condition true-branch false-branch)
     #'(if condition true-branch false-branch)]))

;; Macro para componer múltiples servicios (simulando docker-compose)
(define-syntax (docker-compose stx)
  (syntax-case stx ()
    [(_ [service-name dockerfile] ...)
     #'(list (cons 'service-name dockerfile) ...)]))

;; Variable global para gestores de paquetes disponibles
(define available-package-managers
  (list "apk" "apt-get" "yum" "dnf" "zypper"))
