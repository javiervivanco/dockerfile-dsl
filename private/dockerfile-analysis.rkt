#lang racket/base

(require "dockerfile-core.rkt"
         "dockerfile-ir.rkt"
         racket/match
         racket/list
         racket/string)

(provide analyze-dockerfile
         estimate-image-size
         generate-security-report
         dockerfile-complexity-score
         suggest-improvements
         ;; Funciones adicionales para Iteración 5
         validate-security)

;; === ANÁLISIS ESTÁTICO AVANZADO ===

(define (analyze-dockerfile df)
  "Análisis completo de un Dockerfile"
  (define commands (dockerfile-commands df))
  (hash 'basic-info (basic-analysis commands)
        'security (security-analysis commands)
        'performance (performance-analysis commands)
        'best-practices (best-practices-analysis commands)
        'complexity (complexity-analysis commands)))

(define (basic-analysis commands)
  (hash 'total-commands (length commands)
        'base-images (extract-base-images commands)
        'exposed-ports (extract-all-exposed-ports commands)
        'working-directories (extract-workdirs commands)
        'environment-variables (extract-env-vars commands)
        'users (extract-users commands)))

(define (security-analysis commands)
  (define issues '())

  ;; Verificar usuario root
  (unless (has-user-command? commands)
    (set! issues (cons (hash 'type 'security
                             'severity 'high
                             'message "No USER command - running as root"
                             'recommendation "Add USER command to run as non-root")
                       issues)))

  ;; Verificar puertos problemáticos
  (define dangerous-ports '(22 23 3389 5432 3306))
  (define exposed (extract-all-exposed-ports commands))
  (for ([port (apply append exposed)])
    (when (member port dangerous-ports)
      (set! issues (cons (hash 'type 'security
                               'severity 'medium
                               'message (format "Dangerous port ~a exposed" port)
                               'recommendation "Consider if this port exposure is necessary")
                         issues))))

  ;; Verificar secretos en ENV
  (define env-vars (extract-env-vars commands))
  (for ([var env-vars])
    (when (or (string-contains? (cdr var) "password")
              (string-contains? (cdr var) "secret")
              (string-contains? (cdr var) "key"))
      (set! issues (cons (hash 'type 'security
                               'severity 'high
                               'message (format "Potential secret in ENV: ~a" (car var))
                               'recommendation "Use Docker secrets or build-time arguments")
                         issues))))

  issues)

(define (performance-analysis commands)
  (define suggestions '())

  ;; Analizar capas innecesarias
  (define consecutive-runs (count-consecutive-runs commands))
  (when (> consecutive-runs 3)
    (set! suggestions (cons (hash 'type 'performance
                                  'message "Multiple consecutive RUN commands found"
                                  'recommendation "Combine RUN commands to reduce layers")
                            suggestions)))

  ;; Analizar orden de COPY
  (define copy-order-issue (analyze-copy-order commands))
  (when copy-order-issue
    (set! suggestions (cons copy-order-issue suggestions)))

  ;; Analizar cache busting
  (define cache-issues (analyze-cache-efficiency commands))
  (set! suggestions (append cache-issues suggestions))

  suggestions)

(define (best-practices-analysis commands)
  (define violations '())

  ;; FROM debe ser el primer comando (excepto ARG)
  (unless (valid-from-position? commands)
    (set! violations (cons "FROM is not the first command (except ARG)" violations)))

  ;; Verificar .dockerignore implícito
  (when (has-broad-copy? commands)
    (set! violations (cons "Broad COPY commands found - ensure .dockerignore exists" violations)))

  ;; Verificar limpieza de cache
  (unless (has-cache-cleanup? commands)
    (set! violations (cons "No package cache cleanup found" violations)))

  violations)

(define (complexity-analysis commands)
  (define base-complexity (length commands))
  (define multi-stage-penalty (* (count-from-commands commands) 2))
  (define option-complexity (count-commands-with-options commands))

  (+ base-complexity multi-stage-penalty option-complexity))

;; === FUNCIONES DE UTILIDAD ===

(define (extract-base-images commands)
  (filter-map (lambda (cmd)
                (if (and (dockerfile-command? cmd)
                         (eq? (dockerfile-command-type cmd) 'from))
                    (car (dockerfile-command-args cmd))
                    #f))
              commands))

(define (extract-all-exposed-ports commands)
  (filter-map (lambda (cmd)
                (if (and (dockerfile-command? cmd)
                         (eq? (dockerfile-command-type cmd) 'expose))
                    (dockerfile-command-args cmd)
                    #f))
              commands))

(define (extract-workdirs commands)
  (filter-map (lambda (cmd)
                (if (and (dockerfile-command? cmd)
                         (eq? (dockerfile-command-type cmd) 'workdir))
                    (car (dockerfile-command-args cmd))
                    #f))
              commands))

(define (extract-env-vars commands)
  (apply append
         (filter-map (lambda (cmd)
                       (if (and (dockerfile-command? cmd)
                                (eq? (dockerfile-command-type cmd) 'env))
                           (dockerfile-command-args cmd)
                           #f))
                     commands)))

(define (extract-users commands)
  (filter-map (lambda (cmd)
                (if (and (dockerfile-command? cmd)
                         (eq? (dockerfile-command-type cmd) 'user))
                    (car (dockerfile-command-args cmd))
                    #f))
              commands))

(define (has-user-command? commands)
  (findf (lambda (cmd)
           (and (dockerfile-command? cmd)
                (eq? (dockerfile-command-type cmd) 'user)))
         commands))

(define (count-consecutive-runs commands)
  (define (count-consecutive lst count max-count)
    (cond
      [(null? lst) max-count]
      [(and (dockerfile-command? (car lst))
            (eq? (dockerfile-command-type (car lst)) 'run))
       (count-consecutive (cdr lst) (+ count 1) (max max-count (+ count 1)))]
      [else
       (count-consecutive (cdr lst) 0 max-count)]))
  (count-consecutive commands 0 0))

(define (analyze-copy-order commands)
  ;; Verificar si archivos que cambian frecuentemente están antes que dependencias
  (define copy-commands (filter (lambda (cmd)
                                  (and (dockerfile-command? cmd)
                                       (eq? (dockerfile-command-type cmd) 'copy)))
                                commands))

  ;; Heurística: si hay COPY de todo (.) antes de COPY de package files
  (define has-dot-copy (findf (lambda (cmd)
                                (member "." (dockerfile-command-args cmd)))
                              copy-commands))
  (define has-package-copy (findf (lambda (cmd)
                                    (ormap (lambda (arg)
                                             (or (string-contains? arg "package")
                                                 (string-contains? arg "requirements")
                                                 (string-contains? arg "go.mod")))
                                           (dockerfile-command-args cmd)))
                                  copy-commands))

  (if (and has-dot-copy has-package-copy
           (< (find-element-index copy-commands has-dot-copy)
              (find-element-index copy-commands has-package-copy)))
      (hash 'type 'performance
            'message "Dependencies COPY after source code COPY"
            'recommendation "Copy dependency files before source code for better caching")
      #f))

(define (analyze-cache-efficiency commands)
  (define issues '())

  ;; Verificar apt-get update sin install
  (define apt-update-alone?
    (findf (lambda (cmd)
             (and (dockerfile-command? cmd)
                  (eq? (dockerfile-command-type cmd) 'run)
                  (equal? (dockerfile-command-args cmd) '("apt-get update"))))
           commands))

  (when apt-update-alone?
    (set! issues (cons (hash 'type 'performance
                             'message "apt-get update in separate RUN command"
                             'recommendation "Combine apt-get update with apt-get install")
                       issues)))

  issues)

(define (valid-from-position? commands)
  (if (null? commands)
      #f
      (let ([first-non-arg (findf (lambda (cmd)
                                    (and (dockerfile-command? cmd)
                                         (not (eq? (dockerfile-command-type cmd) 'arg))))
                                  commands)])
        (and first-non-arg
             (eq? (dockerfile-command-type first-non-arg) 'from)))))

(define (has-broad-copy? commands)
  (findf (lambda (cmd)
           (and (dockerfile-command? cmd)
                (eq? (dockerfile-command-type cmd) 'copy)
                (member "." (dockerfile-command-args cmd))))
         commands))

(define (has-cache-cleanup? commands)
  (findf (lambda (cmd)
           (and (dockerfile-command? cmd)
                (eq? (dockerfile-command-type cmd) 'run)
                (ormap (lambda (arg)
                         (or (string-contains? arg "apt-get clean")
                             (string-contains? arg "yum clean")
                             (string-contains? arg "rm -rf /var/lib/apt/lists")))
                       (dockerfile-command-args cmd))))
         commands))

(define (count-from-commands commands)
  (length (filter (lambda (cmd)
                    (and (dockerfile-command? cmd)
                         (eq? (dockerfile-command-type cmd) 'from)))
                  commands)))

(define (count-commands-with-options commands)
  (length (filter (lambda (cmd)
                    (and (dockerfile-command? cmd)
                         (not (null? (dockerfile-command-options cmd)))))
                  commands)))

;; === ANÁLISIS DE TAMAÑO DE IMAGEN ===

(define (estimate-image-size df)
  "Estima el tamaño de la imagen basado en comandos"
  (define commands (dockerfile-commands df))
  (define base-size (estimate-base-image-size commands))
  (define layer-sizes (map estimate-layer-size commands))
  (+ base-size (apply + layer-sizes)))

(define (estimate-base-image-size input)
  ;; Puede recibir comandos o lista de imágenes
  (define base-images 
    (if (list? input)
        (if (and (not (null? input)) (dockerfile-command? (car input)))
            (extract-base-images input)  ; es lista de comandos
            input)                       ; es lista de imágenes
        (list input)))                   ; es imagen individual
  
  (define size-map (hash "alpine" 5
                        "ubuntu" 70
                        "debian" 120
                        "centos" 200
                        "node" 900
                        "python" 300
                        "golang" 300
                        "scratch" 0))
  
  (apply + (map (lambda (img)
                  (define base-name (car (string-split img ":")))
                  (hash-ref size-map base-name 100)) ; tamaño por defecto
                base-images)))

(define (estimate-layer-size cmd)
  (cond
    [(not (dockerfile-command? cmd)) 0]
    [(eq? (dockerfile-command-type cmd) 'run)
     (estimate-run-size (dockerfile-command-args cmd))]
    [(eq? (dockerfile-command-type cmd) 'copy)
     (estimate-copy-size (dockerfile-command-args cmd))]
    [(eq? (dockerfile-command-type cmd) 'add)
     (estimate-copy-size (dockerfile-command-args cmd))]
    [else 1])) ; Metadata commands

(define (estimate-run-size args)
  ;; Heurísticas básicas para comandos RUN
  (define command-string (string-join args " "))
  (cond
    [(string-contains? command-string "apt-get install") 50]
    [(string-contains? command-string "npm install") 30]
    [(string-contains? command-string "pip install") 25]
    [(string-contains? command-string "go build") 20]
    [else 5]))

(define (estimate-copy-size args)
  ;; Estimar basado en patrones de archivo
  (define source (car args))
  (cond
    [(equal? source ".") 100]  ; Todo el contexto
    [(string-contains? source "node_modules") 200]
    [(string-contains? source "*.json") 1]
    [else 10]))

;; === GENERACIÓN DE REPORTES ===

(define (generate-security-report df)
  "Genera un reporte completo de seguridad"
  (define analysis (analyze-dockerfile df))
  (define security-issues (hash-ref analysis 'security))

  (hash 'summary (hash 'total-issues (length security-issues)
                       'high-severity (count-by-severity security-issues 'high)
                       'medium-severity (count-by-severity security-issues 'medium)
                       'low-severity (count-by-severity security-issues 'low))
        'issues security-issues
        'recommendations (generate-security-recommendations security-issues)))

(define (count-by-severity issues severity)
  (length (filter (lambda (issue)
                    (eq? (hash-ref issue 'severity) severity))
                  issues)))

(define (generate-security-recommendations issues)
  (map (lambda (issue) (hash-ref issue 'recommendation)) issues))

(define (dockerfile-complexity-score df)
  "Calcula un score de complejidad de 1-100"
  (define analysis (analyze-dockerfile df))
  (min 100 (hash-ref analysis 'complexity)))

(define (suggest-improvements df)
  "Sugiere mejoras específicas para el Dockerfile"
  (define analysis (analyze-dockerfile df))
  (append (hash-ref analysis 'security)
          (hash-ref analysis 'performance)))

;; Función auxiliar para encontrar índice de elemento en lista
(define (find-element-index lst element)
  (define (find-index lst element index)
    (cond
      [(null? lst) #f]
      [(equal? (car lst) element) index]
      [else (find-index (cdr lst) element (+ index 1))]))
  (find-index lst element 0))

;; Función auxiliar para string-contains?
(define (string-contains? str substr)
  (and (string? str) (string? substr)
       (> (string-length str) 0)
       (regexp-match? (regexp-quote substr) str)))

;; === FUNCIONES ADICIONALES PARA ITERACIÓN 5 ===

;; Validación específica de seguridad
(define (validate-security df)
  "Valida prácticas de seguridad en un Dockerfile"
  (define commands (dockerfile-commands df))
  (define security-issues (security-analysis commands))
  
  ;; Extraer información de seguridad
  (define has-user (has-user-command? commands))
  (define runs-as-root (not has-user))
  (define has-secrets (any (lambda (cmd)
                            (and (equal? (dockerfile-command-type cmd) 'env)
                                 (any (lambda (arg) 
                                       (or (string-contains? arg "PASSWORD")
                                           (string-contains? arg "SECRET")
                                           (string-contains? arg "TOKEN")))
                                      (dockerfile-command-args cmd))))
                          commands))
  
  (hash 'is-secure (and has-user (not runs-as-root) (not has-secrets))
        'has-user has-user
        'runs-as-root runs-as-root
        'has-secrets has-secrets
        'issues (map (lambda (issue) (hash-ref issue 'message)) security-issues)
        'recommendations (map (lambda (issue) (hash-ref issue 'recommendation)) security-issues)))

;; === FUNCIONES AUXILIARES PARA VALIDACIONES AVANZADAS ===

(define (check-privileged-operations commands)
  "Verifica operaciones privilegiadas"
  (filter (lambda (cmd)
            (and (equal? (dockerfile-command-type cmd) 'run)
                 (any (lambda (arg)
                        (or (string-contains? arg "sudo")
                            (string-contains? arg "su ")
                            (string-contains? arg "chmod 777")))
                      (dockerfile-command-args cmd))))
          commands))

(define (check-package-management commands)
  "Verifica buenas prácticas en gestión de paquetes"
  (define package-commands
    (filter (lambda (cmd)
              (and (equal? (dockerfile-command-type cmd) 'run)
                   (any (lambda (arg)
                          (or (string-contains? arg "apt-get")
                              (string-contains? arg "yum")
                              (string-contains? arg "apk")))
                        (dockerfile-command-args cmd))))
            commands))
  (map (lambda (cmd)
         (hash 'command cmd
               'has-update (any (lambda (arg) (string-contains? arg "update"))
                               (dockerfile-command-args cmd))
               'has-cleanup (any (lambda (arg) 
                                  (or (string-contains? arg "clean")
                                      (string-contains? arg "autoremove")))
                                (dockerfile-command-args cmd))))
       package-commands))

(define (check-network-security commands)
  "Verifica configuración de seguridad de red"
  (define exposed-ports (extract-all-exposed-ports commands))
  (hash 'exposed-ports exposed-ports
        'has-dangerous-ports (any (lambda (port)
                                   (member port '("22" "3389" "1433" "3306")))
                                 exposed-ports)))

(define (check-file-permissions commands)
  "Verifica permisos de archivos"
  (filter (lambda (cmd)
            (and (equal? (dockerfile-command-type cmd) 'run)
                 (any (lambda (arg)
                        (or (string-contains? arg "chmod")
                            (string-contains? arg "chown")))
                      (dockerfile-command-args cmd))))
          commands))

(define (estimate-package-size commands)
  "Estima el tamaño agregado por paquetes instalados"
  (define install-commands
    (filter (lambda (cmd)
              (and (equal? (dockerfile-command-type cmd) 'run)
                   (any (lambda (arg)
                          (or (string-contains? arg "install")
                              (string-contains? arg "add")))
                        (dockerfile-command-args cmd))))
            commands))
  (* (length install-commands) 50)) ; 50MB por comando de instalación promedio

(define (any pred lst)
  "Verifica si algún elemento de la lista satisface el predicado"
  (cond
    [(null? lst) #f]
    [(pred (car lst)) #t]
    [else (any pred (cdr lst))]))

(define identity (lambda (x) x))
