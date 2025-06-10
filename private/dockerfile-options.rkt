#lang racket/base

(require racket/list
         racket/string
         "dockerfile-core.rkt")

(provide format-mount-option
         format-copy-from-option
         parse-mount-spec
         validate-mount-spec)

;; Formatear especificación de mount para RUN --mount
(define (format-mount-option mount-spec)
  (define pairs
    (map (lambda (pair)
           (format "~a=~a" (car pair) (cdr pair)))
         mount-spec))
  (string-join pairs ","))

;; Formatear opción --from para COPY
(define (format-copy-from-option stage)
  (format "from=~a" stage))

;; Parsear especificación de mount desde lista de pares
(define (parse-mount-spec spec)
  (cond
    [(list? spec) spec]
    [else (error "Mount specification must be a list of pairs")]))

;; Validar especificación de mount básica
(define (validate-mount-spec spec)
  (define required-keys '(type))
  (define provided-keys (map car spec))
  (andmap (lambda (key) (member key provided-keys)) required-keys))
