#lang racket/base

(require racket/list
         "dockerfile-core.rkt")

(provide validate-dockerfile-advanced
         validate-multistage-dependencies
         check-stage-references
         suggest-optimizations
         validate-security-practices
         detect-antipatterns
         estimate-dockerfile-size)

;; Validación avanzada de Dockerfile
(define (validate-dockerfile-advanced df)
  (define commands (dockerfile-commands df))
  (and (validate-first-command commands)
       (validate-healthcheck-placement commands)))

;; Validar que el primer comando sea FROM o ARG
(define (validate-first-command commands)
  (if (empty? commands)
      #t
      (let ([first-cmd (first commands)])
        (member (dockerfile-command-type first-cmd) '(from arg)))))

;; Validar referencias entre stages en multi-stage builds
(define (validate-multistage-dependencies df)
  (define commands (dockerfile-commands df))
  (define stages (extract-stage-names commands))
  (define stage-refs (extract-stage-references commands))
  (andmap (lambda (ref) (member ref stages)) stage-refs))

;; Extraer nombres de stages definidos
(define (extract-stage-names commands)
  (filter-map (lambda (cmd)
                (if (and (eq? (dockerfile-command-type cmd) 'from)
                         (assoc 'as (dockerfile-command-options cmd)))
                    (cdr (assoc 'as (dockerfile-command-options cmd)))
                    #f))
              commands))

;; Extraer referencias a stages
(define (extract-stage-references commands)
  (filter-map (lambda (cmd)
                (if (and (eq? (dockerfile-command-type cmd) 'copy)
                         (assoc 'from (dockerfile-command-options cmd)))
                    (cdr (assoc 'from (dockerfile-command-options cmd)))
                    #f))
              commands))

;; Verificar referencias de stages
(define (check-stage-references df)
  (define commands (dockerfile-commands df))
  (define stages (extract-stage-names commands))
  (define refs (extract-stage-references commands))
  (define undefined-refs (filter (lambda (ref) (not (member ref stages))) refs))
  (if (empty? undefined-refs)
      '()
      undefined-refs))

;; Validar ubicación de HEALTHCHECK
(define (validate-healthcheck-placement commands)
  (define healthcheck-cmds (filter (lambda (cmd)
                                     (eq? (dockerfile-command-type cmd) 'healthcheck))
                                   commands))
  ;; Solo debe haber un HEALTHCHECK
  (<= (length healthcheck-cmds) 1))

;; Sugerir optimizaciones básicas
(define (suggest-optimizations df)
  (define commands (dockerfile-commands df))
  (define suggestions '())

  ;; Verificar múltiples RUN consecutivos
  (define consecutive-runs (count-consecutive-runs commands))
  (when (> consecutive-runs 2)
    (set! suggestions (cons "Considera combinar comandos RUN consecutivos para reducir layers" suggestions)))

  ;; Verificar si COPY viene antes de RUN
  (when (copy-before-deps? commands)
    (set! suggestions (cons "Considera copiar archivos de dependencias antes que el código fuente" suggestions)))

  suggestions)

;; Contar RUN consecutivos
(define (count-consecutive-runs commands)
  (define (count-consecutive cmds current-count max-count)
    (cond
      [(empty? cmds) max-count]
      [(eq? (dockerfile-command-type (first cmds)) 'run)
       (count-consecutive (rest cmds) (+ current-count 1) (max (+ current-count 1) max-count))]
      [else
       (count-consecutive (rest cmds) 0 max-count)]))
  (count-consecutive commands 0 0))

;; Verificar patrón copy-before-deps
(define (copy-before-deps? commands)
  ;; Simplificado: buscar COPY seguido de RUN
  (define copy-run-pairs
    (filter-map (lambda (cmd next-cmd)
                  (and (eq? (dockerfile-command-type cmd) 'copy)
                       (eq? (dockerfile-command-type next-cmd) 'run)))
                commands
                (append (rest commands) '(#f))))
  (> (length copy-run-pairs) 0))

;; Validaciones de seguridad y mejores prácticas
(define (validate-security-practices df)
  (define commands (dockerfile-commands df))
  (and (check-non-root-user commands)
       (check-no-sudo-usage commands)
       (check-explicit-tags commands)))

;; Verificar que se use un usuario no-root
(define (check-non-root-user commands)
  (define user-commands (filter (lambda (cmd)
                                  (eq? (dockerfile-command-type cmd) 'user))
                                commands))
  (or (empty? user-commands)
      (not (member "root" (apply append
                                 (map dockerfile-command-args user-commands))))))

;; Verificar que no se use sudo en RUN
(define (check-no-sudo-usage commands)
  (define run-commands (filter (lambda (cmd)
                                 (eq? (dockerfile-command-type cmd) 'run))
                               commands))
  (not (ormap (lambda (cmd)
                (ormap (lambda (arg) (regexp-match? #rx"sudo" arg))
                       (dockerfile-command-args cmd)))
              run-commands)))

;; Verificar que las imágenes tengan tags explícitos
(define (check-explicit-tags commands)
  (define from-commands (filter (lambda (cmd)
                                  (eq? (dockerfile-command-type cmd) 'from))
                                commands))
  (andmap (lambda (cmd)
            (define image (first (dockerfile-command-args cmd)))
            (regexp-match? #rx":" image))
          from-commands))

;; Detectar anti-patterns comunes
(define (detect-antipatterns df)
  (define commands (dockerfile-commands df))
  (define patterns '())

  ;; Detectar ADD cuando debería ser COPY
  (when (has-unnecessary-add? commands)
    (set! patterns (cons "Usar COPY en lugar de ADD para archivos locales" patterns)))

  ;; Detectar múltiples FROM sin multi-stage
  (when (has-multiple-from-single-stage? commands)
    (set! patterns (cons "Múltiples FROM sin nombres de stage" patterns)))

  ;; Detectar layers innecesarios
  (when (has-unnecessary-layers? commands)
    (set! patterns (cons "Combinar comandos RUN para reducir layers" patterns)))

  patterns)

;; Verificar uso innecesario de ADD
(define (has-unnecessary-add? commands)
  (ormap (lambda (cmd)
           (and (eq? (dockerfile-command-type cmd) 'add)
                (not (regexp-match? #rx"^https?://"
                                    (first (dockerfile-command-args cmd))))))
         commands))

;; Verificar múltiples FROM sin stage names
(define (has-multiple-from-single-stage? commands)
  (define from-commands (filter (lambda (cmd)
                                  (eq? (dockerfile-command-type cmd) 'from))
                                commands))
  (and (> (length from-commands) 1)
       (not (ormap (lambda (cmd) (assoc 'as (dockerfile-command-options cmd)))
                   from-commands))))

;; Verificar layers innecesarios
(define (has-unnecessary-layers? commands)
  (> (count-consecutive-runs commands) 3))

;; Análisis de tamaño estimado
(define (estimate-dockerfile-size df)
  (define commands (dockerfile-commands df))
  (define base-size 50) ; MB base estimado
  (define layer-overhead 5) ; MB por layer
  (define run-weight 10) ; MB por comando RUN
  (define copy-weight 5) ; MB por comando COPY

  (+ base-size
     (* (length commands) layer-overhead)
     (* (length (filter (lambda (cmd) (eq? (dockerfile-command-type cmd) 'run)) commands))
        run-weight)
     (* (length (filter (lambda (cmd) (member (dockerfile-command-type cmd) '(copy add))) commands))
        copy-weight)))
